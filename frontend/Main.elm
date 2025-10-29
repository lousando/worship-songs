module Main exposing (..)

import Browser
import Html exposing (Html, div, text, input, ul, li, h1, span)
import Html.Attributes exposing (class, placeholder, value)
import Html.Events exposing (onInput)
import List
import Http
import Json.Decode exposing (Decoder, field)

-- Main

main =
  Browser.element
  {
    init = init,
    update = update,
    subscriptions = subscriptions,
    view = view
  }

type alias Document msg =
    {
        title : String,
        body : List (Html msg)
    }

-- Model

type alias Model =
    {
        loading: Bool,
        query: String,
        results: List Song
    }

type alias Song =
    {
        name: String,
        page: Int
    }

init : () -> (Model, Cmd Msg)
init _ =
    (
        {
            loading = True,
            query = "",
            results = []
        },
        Http.get
           {
                url = "/api/songs",
                expect = Http.expectJson
                                SongResults songResultDecoder
           }
   )

-- HTTP

songResultDecoder: Decoder (List Song)
songResultDecoder =
    Json.Decode.list (
        Json.Decode.map2 Song
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
subscriptions model =
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
                text "Loading..."
            ]
        else
            div [ class "flex flex-col w-full" ]
                (
                    model.results
                    |> List.filter (\r -> String.contains
                                            (String.toLower model.query)
                                            (String.toLower r.name))
                    |> List.indexedMap songRow
                )
    ]

-- View Utilities
songRow: Int -> Song -> Html msg
songRow index row =
    div[
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
        "bg-slate-100"
    -- odd
    else
        "bg-slate-300"
