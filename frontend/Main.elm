module Main exposing (..)

import Browser
import Html exposing (Html, div, text, input, ul, li, h1, span)
import Html.Attributes exposing (class, placeholder, value)
import Html.Events exposing (onInput)
import List
import Http
import Json.Decode exposing (Decoder, field)
import Json.Encode

-- Main

main =
  Browser.element
  {
    init = init,
    update = update,
    subscriptions = subscriptions,
    view = view
  }

type alias Flags =
    {
        favorites: List String
    }

type alias Document msg =
    {
        title : String,
        body : List (Html msg)
    }

flagDecoder: Decoder Flags
flagDecoder =
    Json.Decode.map Flags
        (field "favorites" (Json.Decode.list Json.Decode.string))

-- Model

type alias Model =
    {
        loading: Bool,
        query: String,
        results: List Song,
        favorites: List String
    }

type alias Song =
    {
        id: String,
        name: String,
        page: Int
    }

init: Json.Encode.Value -> (Model, Cmd Msg)
init rawFlags =
    (
        case (Json.Decode.decodeValue flagDecoder rawFlags) of
          Ok flags ->
            {
                loading = True,
                query = "",
                results = [],
                favorites = flags.favorites
            }
          Err _ ->
            {
                loading = True,
                query = "",
                results = [],
                favorites = []
            }
       ,
        Http.get
           {
                url = "/api/songs",
                expect = Http.expectJson
                                SongResults songResultDecoder
           }
   )

-- Ports

--port setFavorites: List String -> Cmd msg

-- HTTP

songResultDecoder: Decoder (List Song)
songResultDecoder =
    Json.Decode.list (
        Json.Decode.map3 Song
            (field "id" Json.Decode.string)
            (field "name" Json.Decode.string)
            (field "page" Json.Decode.int)
    )

-- Update

type Msg
  = Search String
  | SongResults (Result Http.Error (List Song))

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Search newQuery ->
        (
            { model | query = newQuery },
            Cmd.none
        )
    SongResults httpResponse ->
      case httpResponse of
        Ok res ->
          ({ model | loading = False, results = res }, Cmd.none)
        Err _ ->
          (model, Cmd.none)

-- Subscriptions

subscriptions: Model -> Sub Msg
subscriptions _ =
  Sub.none

-- View

view : Model -> Html Msg
view model =
  div [ class "flex flex-col items-center" ]
    [
        h1 [] [ text "Worship Songs" ],
        input [
            Html.Attributes.type_ "search",
            placeholder "Search...",
            value model.query,
            onInput Search,
            class "w-full"
        ] [],
        if model.loading then
            div [ class "flex flex-row justify-center w-full" ]
            [
                -- todo: add a cool loading animation here
                text "Loading..."
            ]
        else
            div [ class "flex flex-col w-full" ]
                (
                    model.results
                    |> List.filter (\r -> songFilter model.query r.name)
                    |> List.indexedMap songRow
                )
    ]

-- View Utilities
cleanSongName: String -> String
cleanSongName name =
    name
    |> String.toLower
    |> String.trim
    -- todo: sanitize DB so these cases aren't needed
    |> String.replace "'" ""
    |> String.replace "’" ""

songFilter: String -> String -> Bool
songFilter query songName =
    String.contains
        (cleanSongName query)
        (cleanSongName songName)

songRow: Int -> Song -> Html msg
songRow index row =
    div[
        Html.Attributes.id ("song-" ++ row.id),
        class "flex flex-row justify-between leading-8 text-base",
        class (songRowColor index)
    ]
    [
        span [ class "text-left truncate" ] [text row.name],
        span [ class "text-right basis-[4ch]" ] [text (String.fromInt row.page)]
    ]

songRowColor: Int -> String
songRowColor index =
    -- even
    if ((modBy 2 index) == 0) then
        "bg-slate-100 dark:bg-slate-700"
    -- odd
    else
        "bg-slate-300 dark:bg-slate-900"
