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
    { repos : List Repo
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
    ( { repos = []
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
            { model | repos = repos } ! []

        SetSortOrder order ->
            { model | order = order } ! []

        Toggle get set ->
            (get model |> not |> set model) ! []



-- VIEW


view : Model -> Html Msg
view model =
    let
        repos =
            model.repos
                |> List.filter (modelFilter model)
                |> modelSorter model
                |> List.reverse
    in
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
            List.sortBy .name

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
        , ( "Archived", .isArchived )
        ]
            |> catchAll


categoryViews : ( String, Repo -> Bool ) -> List Repo -> Html msg
categoryViews ( name, filter ) repos =
    let
        filtered =
            List.filter filter repos
    in
        if List.isEmpty filtered then
            emptyDiv
        else
            Html.div []
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

        status =
            case ( repo.isArchived, repoHasTopic "under-construction" repo ) of
                ( True, _ ) ->
                    Just "archived"

                ( _, True ) ->
                    Just "under construction"

                _ ->
                    Nothing
    in
        Html.li [ class "project" ] <|
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

                -- , ifJust (not <| List.isEmpty repo.topics) <| Html.div [] [ text <| "Topics: " ++ String.join ", " repo.topics ]
                ]


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



-- DATA


type alias Repo =
    { name : String
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
