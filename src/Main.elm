module Main exposing (..)

import Browser
import Html exposing (Html, div, text, input, ul, li)
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
        pageNumber: String
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
                -- todo: update to a real endpoint
                url = "https://jsonplaceholder.typicode.com/posts",
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
            (field "pageNumber" Json.Decode.string)
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
          ({ model | results = res }, Cmd.none)
        Err _ ->
          (model, Cmd.none)

-- Subscriptions

subscriptions: Model -> Sub Msg
subscriptions model =
  Sub.none

-- View

view : Model -> Html Msg
view model =
  div [ class "" ]
    [
        input [ placeholder "Search...", value model.query, onInput Search ] [],
        ul []
            (List.map (\r -> li[][text r.name]) model.results)
    ]