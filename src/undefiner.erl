-module(undefiner).
-export([encode/1, decode/1]).
%% custom encoder callback
-export([encode/2]).
%% custom decoder callbacks
-export([init/1, handle_event/2]).


encode(Term) ->
    %% the parser is unmodified but the term passed to the parser instance is
    %% preencoded by the custom `encode/2` function below
    (jsx:parser(jsx_to_json, [], [escaped_strings]))(encode(Term, ?MODULE) ++ [end_json]).

%% this captures any instance of `undefined` as a top level term, the value for a
%% map or proplist entry or a member of a list and returns `null` to the parser
%% instead. anything else is handled by the default parser in `jsx_encoder`
encode(undefined, _EntryPoint) -> [null];
encode(Term, EntryPoint) -> jsx_encoder:encode(Term, EntryPoint).


decode(JSON) -> (jsx:decoder(?MODULE, [], []))(JSON).

init(Config) -> jsx_to_term:init(Config).

%% convert `null` in input to `undefined` in output. let `jsx_to_term` handle
%% anything else
handle_event({literal, null}, State) -> jsx_to_term:handle_event({literal, undefined}, State);
handle_event(Event, State) -> jsx_to_term:handle_event(Event, State).


-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

encode_test_() ->
  [{"encode undefined", ?_assertEqual(<<"null">>, encode(undefined))},
   {"encode list", ?_assertEqual(<<"[true,false,null]">>, encode([true, false, undefined]))},
   {"encode proplist", ?_assertEqual(
     <<"{\"meaning of life?\":null}">>,
     encode([{<<"meaning of life?">>, undefined}])
   )}].

decode_test_() ->
  [{"decode null", ?_assertEqual(undefined, decode(<<"null">>))},
   {"decode list", ?_assertEqual([true,false,undefined], decode(<<"[true,false,null]">>))},
   {"decode object", ?_assertEqual(
     [{<<"meaning of life?">>, undefined}],
     decode(<<"{\"meaning of life?\":null}">>)
   )}].

-endif.