module Main exposing (main)

import Browser
import Html exposing (Html, text)
import Html.Attributes exposing (class, href)
import Html.Events exposing (onClick)
import Http
import Iso8601
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as Decode
import Json.Decode.Pipeline as Pipeline
import Regex
import Time exposing (toMonth, toYear, utc)


type alias Time =
    Time.Posix


type alias TimeZone =
    Time.Zone



-- MAIN


main : Program Decode.Value Model Msg
main =
    Browser.element
        { init = \repos -> init repos
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }



-- MODEL


type alias Model =
    { tz : TimeZone
    , repos : Maybe (List Repo)
    , error : Maybe String
    , order : SortOrder
    , archived : Bool
    , underConstruction : Bool
    }


type SortOrder
    = ByName
    | ByCreation
    | ByUpdate


init : Decode.Value -> ( Model, Cmd Msg )
init repoJson =
    let
        model =
            { tz = utc
            , repos = Nothing
            , error = Nothing
            , order = ByName
            , archived = False
            , underConstruction = False
            }

        msg =
            SetRepos <| Decode.decodeValue (Decode.list decodeRepo) repoJson
    in
        update msg model


setArchived : Model -> Bool -> Model
setArchived model value =
    { model | archived = value }


setUnderConstruction : Model -> Bool -> Model
setUnderConstruction model value =
    { model | underConstruction = value }



-- UPDATE


type Msg
    = SetRepos (Result Decode.Error (List Repo))
    | SetSortOrder SortOrder
    | Toggle (Model -> Bool) (Model -> Bool -> Model)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetRepos (Result.Err err) ->
            ( { model | error = Just <| "error decoding JSON" ++ Decode.errorToString err }
            , Cmd.none
            )

        SetRepos (Result.Ok repos) ->
            ( { model | repos = Just repos }
            , Cmd.none
            )

        SetSortOrder order ->
            ( { model | order = order }
            , Cmd.none
            )

        Toggle get set ->
            ( get model |> not |> set model
            , Cmd.none
            )



-- VIEW


view : Model -> Html Msg
view model =
    let
        toolbar =
            Html.div [ class "ui container" ]
                [ Html.div [ class "ui borderless main menu" ]
                    [ Html.div [ class "ui buttons" ]
                        [ Html.div [ class "ui label" ] [ text "Include" ]
                        , filterToggle "Archived" (Toggle .archived setArchived)
                        , filterToggle "Under Construction" (Toggle .underConstruction setUnderConstruction)
                        ]
                    , Html.div [ class "ui buttons" ]
                        [ Html.div [ class "ui label" ] [ text "Sort by" ]
                        , sortOrderButton model ByName "Name" "name"
                        , sortOrderButton model ByCreation "Created" "repo creation date"
                        , sortOrderButton model ByUpdate "Updated" "latest commit"
                        ]
                    ]
                ]
    in
        case model.repos of
            Just _ ->
                Html.div [ class "projects" ]
                    [ toolbar
                    , Html.div [ class "ui vertical segment" ] [ categoriesView model ]
                    ]

            Nothing ->
                Html.div [ class "ui segment" ]
                    [ Html.div [ class "ui active text loader" ]
                        [ text "Loading…" ]
                    , Html.p []
                        [ text <| Maybe.withDefault "" model.error ]
                    ]


categoryId : ( String, a ) -> String
categoryId ( title, _ ) =
    "category-" ++ slugify title


categoriesView : Model -> Html Msg
categoriesView model =
    let
        repos =
            Maybe.withDefault [] model.repos
                |> List.filter (.owner >> (\a -> List.member a owners))
                |> List.filter (modelFilter model)
                |> modelSorter model
                |> List.reverse

        sortKey =
            case model.order of
                ByName ->
                    always 0

                ByCreation ->
                    .createdAt >> Time.posixToMillis >> negate

                ByUpdate ->
                    .pushedAt >> Time.posixToMillis >> negate

        cats =
            categories
                |> List.filter (not << List.isEmpty << (\a -> categoryRepos a repos))
                |> List.sortBy ((\a -> categoryRepos a repos) >> List.head >> Maybe.map sortKey >> Maybe.withDefault 0)
    in
        Html.div [] <|
            [ Html.div [ class "ui basic segment" ]
                [ Html.div [ class "ui horizontal list" ]
                    ((\a -> List.map a cats) <|
                        \cat ->
                            Html.div [ class "ui label" ]
                                [ Html.a [ href <| "#" ++ categoryId cat ]
                                    [ text <| Tuple.first cat ]
                                ]
                    )
                ]
            ]
                ++ List.map (\a -> categoryView model.tz a repos) cats


filterToggle : String -> a -> Html a
filterToggle label cmd =
    Html.div [ class "ui checkbox" ]
        [ Html.input
            [ Html.Attributes.type_ "checkbox"
            , onClick cmd
            ]
            []
        , Html.label [] [ text label ]
        ]


sortOrderButton : Model -> SortOrder -> String -> String -> Html Msg
sortOrderButton model order label description =
    Html.button
        [ class "ui button"
        , activeClass <| model.order == order
        , onClick <| SetSortOrder order
        ]
        [ text label
        ]


modelFilter : Model -> Repo -> Bool
modelFilter { archived, underConstruction } repo =
    List.all (\( flag, f ) -> not flag || f repo) <|
        [ ( not archived, not << .isArchived )
        , ( not underConstruction, not << repoHasTopic "under-construction" )
        ]


modelSorter : Model -> List Repo -> List Repo
modelSorter { order } =
    case order of
        ByName ->
            List.sortBy .name >> List.reverse

        ByCreation ->
            List.sortBy (.createdAt >> Time.posixToMillis)

        ByUpdate ->
            List.sortBy (.pushedAt >> Time.posixToMillis)


categories : List ( String, Repo -> Bool )
categories =
    let
        topic =
            repoHasTopic

        startsWith prefix =
            String.startsWith prefix << .name

        catchAll cats =
            let
                filters =
                    List.map Tuple.second cats
            in
                cats ++ [ ( "Other", \r -> not (List.any (\f -> f r) filters) ) ]
    in
        [ ( "Web Apps", topic "webapp" )
        , ( "Command Line Tools", topic "cli" )
        , ( "Chrome Extension", topic "chrome-extension" )
        , ( "Jupyter Extensions", topic "jupyter-notebook-extension" )
        , ( "Jupyter Notebooks", topic "jupyter-notebook" )
        , ( "Python Packages", topic "python-package" )
        , ( "Go Packages", topic "golang-package" )
        , ( "Education", topic "education" )
        , ( "Music Theory", topic "music-theory" )
        , ( "Home Automation", topic "home-automation" )
        , ( "Grunt Plugins", startsWith "grunt-" )
        , ( "OpenLaszlo", topic "open-laszlo" )
        , ( "JavaScript Libraries", topic "javascript-library" )
        , ( "Ruby Gems", topic "ruby-gem" )
        , ( "Rails Plugins", topic "rails-plugins" )
        , ( "Websites", topic "website" )
        , ( "Personal", topic "personal" )
        ]
            |> catchAll


categoryRepos : ( String, Repo -> Bool ) -> List Repo -> List Repo
categoryRepos ( _, filter ) repos =
    List.filter filter repos


categoryView : TimeZone -> ( String, Repo -> Bool ) -> List Repo -> Html msg
categoryView tz ( name, filter ) repos =
    let
        filtered =
            List.filter filter repos
    in
        if List.isEmpty filtered then
            emptyDiv
        else
            Html.div [ class "ui basic segment", Html.Attributes.id <| categoryId ( name, filter ) ]
                [ Html.div [ class "ui medium header" ] [ text name ]
                , Html.div [ class "ui five stackable cards" ] <|
                    List.map (repoCard tz) filtered
                ]


dateRange : TimeZone -> Time -> Time -> String
dateRange tz startDate endDate =
    let
        dateString date =
            -- Date.Format.format "%-m/%y"
            (toMonth tz date |> monthNumber) ++ "/" ++ (toYear tz date |> String.fromInt)

        monthNumber month =
            case month of
                Time.Jan ->
                    "01"

                Time.Feb ->
                    "02"

                Time.Mar ->
                    "03"

                Time.Apr ->
                    "04"

                Time.May ->
                    "05"

                Time.Jun ->
                    "06"

                Time.Jul ->
                    "07"

                Time.Aug ->
                    "08"

                Time.Sep ->
                    "09"

                Time.Oct ->
                    "10"

                Time.Nov ->
                    "11"

                Time.Dec ->
                    "12"

        from =
            dateString startDate

        to =
            dateString endDate
    in
        if from == to then
            from
        else
            from ++ "–" ++ to


repoCard : TimeZone -> Repo -> Html msg
repoCard tz repo =
    let
        link =
            Maybe.withDefault repo.url repo.homepageUrl

        statusInfo =
            case ( repo.isArchived, repoHasTopic "under-construction" repo ) of
                ( True, _ ) ->
                    Just ( "archived", "archived" )

                ( _, True ) ->
                    Just ( "under construction", "under-construction" )

                _ ->
                    Nothing

        status =
            Maybe.map Tuple.first statusInfo

        projectClass =
            "project ui card " ++ Maybe.withDefault "" (Maybe.map Tuple.second statusInfo)

        card header meta description extraContent =
            Html.div [ class projectClass ]
                [ Html.div [ class "content" ]
                    [ Html.div [ class "header" ] [ header ]
                    , Html.div [ class "meta" ] [ meta ]
                    , Html.div [ class "description" ] [ description ]
                    ]
                , Html.div [ class "extra content" ] [ extraContent ]
                ]
    in
        card (Html.a [ href link ] [ text repo.name ])
            (Html.div [] <|
                List.filterMap identity
                    [ Just <| text " "
                    , ifJust (link /= repo.url) <| Html.a [ href repo.url ] [ text "(source)" ]
                    , Just <| text <| " " ++ dateRange tz repo.createdAt repo.pushedAt
                    ]
            )
            (Html.div [] [ text <| Maybe.withDefault "" repo.description ])
            (Html.div [] <|
                List.filterMap identity
                    [ (\a -> Maybe.map a status) <|
                        \s ->
                            Html.div [ class "status" ] [ text <| "Status: " ++ s ]
                    , Just <|
                        Html.div [ class "languages" ] <|
                            [ text "Languages: "
                            , Html.ul [] <|
                                List.map
                                    (\s ->
                                        Html.li
                                            [ class <|
                                                if Just s == repo.primaryLanguage then
                                                    "primary"
                                                else
                                                    "secondary"
                                            ]
                                            [ text s ]
                                    )
                                    repo.languages
                            ]
                    , ifJust (not <| List.isEmpty repo.topics) <|
                        Html.div [ class "topics" ]
                            [ text "Topics: "
                            , Html.ul [] <| List.map (\s -> Html.li [] [ text s ]) repo.topics
                            ]
                    ]
            )



-- CONFIGURATION


ownerName : String
ownerName =
    "osteele"


owners : List String
owners =
    [ ownerName, "olin-computing", "olin-build", "mlsteele" ]



-- DATA


type alias Repo =
    { name : String
    , owner : String
    , description : Maybe String
    , url : String
    , homepageUrl : Maybe String
    , createdAt : Time
    , pushedAt : Time
    , isArchived : Bool
    , primaryLanguage : Maybe String
    , languages : List String
    , topics : List String
    }


decodeRepo : Decoder Repo
decodeRepo =
    let
        optional name decoder =
            Pipeline.optional name (Decode.map Just decoder) Nothing

        required =
            Pipeline.required
    in
        Decode.succeed Repo
            |> required "name" Decode.string
            |> required "owner" (Decode.field "login" Decode.string)
            |> optional "description" Decode.string
            |> required "url" Decode.string
            |> optional "homepageUrl" Decode.string
            |> required "createdAt" Iso8601.decoder
            |> required "pushedAt" Iso8601.decoder
            |> required "isArchived" Decode.bool
            |> optional "primaryLanguage" Decode.string
            |> required "languages" (Decode.list Decode.string)
            |> required "topics" (Decode.list Decode.string)


repoHasTopic : String -> Repo -> Bool
repoHasTopic name =
    List.any ((==) name) << .topics



-- UTILS


activeClass : Bool -> Html.Attribute msg
activeClass test =
    class <|
        if test then
            "active"
        else
            ""


emptyDiv : Html msg
emptyDiv =
    Html.div [] []


ifJust : Bool -> a -> Maybe a
ifJust test a =
    if test then
        Just a
    else
        Nothing


slugifyRe : Regex.Regex
slugifyRe =
    Regex.fromString "[^a-zA-Z0-9]+"
        |> Maybe.withDefault Regex.never


slugify : String -> String
slugify =
    String.toLower >> Regex.replace slugifyRe (\_ -> "-")
