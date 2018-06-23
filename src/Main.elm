module Main exposing (main)

import Date exposing (Date)
import Date.Format
import Html exposing (Html, text)
import Html.Attributes exposing (class, href)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as Decode
import Json.Decode.Pipeline as Pipeline
import Regex


-- MAIN


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }



-- MODEL


type alias Model =
    { repos : Maybe (List Repo)
    , order : SortOrder
    , archived : Bool
    , underConstruction : Bool
    }


type SortOrder
    = ByName
    | ByCreation
    | ByUpdate


init : ( Model, Cmd Msg )
init =
    ( { repos = Nothing
      , order = ByName
      , archived = False
      , underConstruction = False
      }
    , Http.send SetRepos (Http.get "../data/repos.json" (Decode.list decodeRepo))
    )


setArchived : Model -> Bool -> Model
setArchived model value =
    { model | archived = value }


setUnderConstruction : Model -> Bool -> Model
setUnderConstruction model value =
    { model | underConstruction = value }



-- UPDATE


type Msg
    = SetRepos (Result Http.Error (List Repo))
    | SetSortOrder SortOrder
    | Toggle (Model -> Bool) (Model -> Bool -> Model)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetRepos (Result.Err err) ->
            let
                _ =
                    Debug.log "error decoding JSON" err
            in
                model ! []

        SetRepos (Result.Ok repos) ->
            { model | repos = Just repos } ! []

        SetSortOrder order ->
            { model | order = order } ! []

        Toggle get set ->
            (get model |> not |> set model) ! []



-- VIEW


view : Model -> Html Msg
view model =
    Html.div [ class "projects" ] <|
        [ text "Include:"
        , checkbox "Archived" (Toggle .archived setArchived)
        , checkbox "Under Construction" (Toggle .underConstruction setUnderConstruction)
        , Html.fieldset []
            [ text "Sort:"
            , radio model "Name" ByName
            , radio model "Created" ByCreation
            , radio model "Updated" ByUpdate
            ]
        , case model.repos of
            Just repos ->
                categoriesView model

            Nothing ->
                Html.div [ class "loading" ] [ text "Loading…" ]
        ]


slugify : String -> String
slugify =
    String.toLower >> Regex.replace Regex.All (Regex.regex "[^a-zA-Z0-9]+") (\_ -> "-")


categoryId : ( String, a ) -> String
categoryId ( title, _ ) =
    "category-" ++ slugify title


categoriesView : Model -> Html Msg
categoriesView model =
    let
        repos =
            Maybe.withDefault [] model.repos
                |> List.filter (.owner >> flip List.member owners)
                |> List.filter (modelFilter model)
                |> modelSorter model
                |> List.reverse

        cats =
            List.filter (not << List.isEmpty << flip categoryRepos repos) categories
    in
        Html.div [] <|
            [ Html.ul [ class "toc" ]
                (List.map
                    (\cat ->
                        Html.li []
                            [ Html.a [ href <| "#" ++ categoryId cat ]
                                [ text <| Tuple.first cat ]
                            ]
                    )
                    cats
                )
            ]
                ++ List.map (flip categoryViews repos) categories


checkbox : String -> a -> Html a
checkbox label cmd =
    Html.label []
        [ Html.input
            [ Html.Attributes.type_ "checkbox"
            , onClick cmd
            ]
            []
        , text label
        ]


radio : Model -> String -> SortOrder -> Html Msg
radio model label order =
    Html.label []
        [ Html.input
            [ Html.Attributes.type_ "radio"
            , Html.Attributes.name "sort-order"
            , Html.Attributes.checked (model.order == order)
            , onClick <| SetSortOrder order
            ]
            []
        , text label
        ]


modelFilter : Model -> Repo -> Bool
modelFilter { archived, underConstruction } repo =
    List.all (\( flag, f ) -> not flag || f repo) <|
        [ ( not archived, (not << .isArchived) )
        , ( not underConstruction, not << repoHasTopic "under-construction" )
        ]


modelSorter : Model -> List Repo -> List Repo
modelSorter { order } =
    case order of
        ByName ->
            List.sortBy .name >> List.reverse

        ByCreation ->
            List.sortBy (Date.toTime << .createdAt)

        ByUpdate ->
            List.sortBy (.pushedAt >> Date.toTime)


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
        , ( "Command Line", topic "cli" )
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


categoryViews : ( String, Repo -> Bool ) -> List Repo -> Html msg
categoryViews ( name, filter ) repos =
    let
        filtered =
            List.filter filter repos
    in
        if List.isEmpty filtered then
            emptyDiv
        else
            Html.div [ Html.Attributes.id <| categoryId ( name, filter ) ]
                [ Html.h2 [] [ text name ]
                , Html.ul [] <|
                    List.map repoView filtered
                ]


dateRange : Date -> Date -> String
dateRange startDate endDate =
    let
        dateString =
            Date.Format.format "%-m/%y"

        from =
            dateString startDate

        to =
            dateString endDate
    in
        if from == to then
            from
        else
            from ++ "–" ++ to


repoView : Repo -> Html msg
repoView repo =
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
            "project " ++ Maybe.withDefault "" (Maybe.map Tuple.second statusInfo)
    in
        Html.li [ class projectClass ] <|
            List.filterMap
                identity
                [ Just <| Html.a [ href link ] [ text repo.name ]
                , Just <| text " "
                , ifJust (link /= repo.url) <| Html.a [ href repo.url ] [ text "(source)" ]
                , Just <| text <| " " ++ dateRange repo.createdAt repo.pushedAt
                , (flip Maybe.map repo.description) <| \d -> text <| " — " ++ d
                , (flip Maybe.map status) <|
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
    , createdAt : Date
    , pushedAt : Date
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
        Pipeline.decode Repo
            |> required "name" Decode.string
            |> required "owner" (Decode.field "login" Decode.string)
            |> optional "description" Decode.string
            |> required "url" Decode.string
            |> optional "homepageUrl" Decode.string
            |> required "createdAt" Decode.date
            |> required "pushedAt" Decode.date
            |> required "isArchived" Decode.bool
            |> optional "primaryLanguage" Decode.string
            |> required "languages" (Decode.list Decode.string)
            |> required "topics" (Decode.list Decode.string)


repoHasTopic : String -> Repo -> Bool
repoHasTopic name =
    List.any ((==) name) << .topics



-- UTILS


ifJust : Bool -> a -> Maybe a
ifJust test a =
    if test then
        Just a
    else
        Nothing


emptyDiv : Html msg
emptyDiv =
    Html.div [] []


emptySpan : Html msg
emptySpan =
    Html.span [] []
