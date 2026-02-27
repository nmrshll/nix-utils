{ l }:
let
  tests.flatMapPkgs = {
    simple = {
      input = { x = 1; y = 2; };
      expected = { x = 1; y = 2; };
    };
    nested = {
      input = { a = { b = 1; }; };
      expected = { "a.b" = 1; };
    };
    deep = {
      input = { x = { y = { z = 42; }; }; };
      expected = { "x.y.z" = 42; };
    };
  };

  runTest = name: t:
    let res = l.flatMapPkgs t.input;
    in assert res == t.expected ||
      builtins.trace "FAIL: ${name}" false;
    builtins.trace "PASS: ${name}" res;
  allTests = builtins.mapAttrs runTest tests.flatMapPkgs;


in
{
  # TODO here add tests to flake.checks
}
