package ammer.stub;

import ammer.Ammer.AmmerContext;

interface Stub {
  function generate(ctx:AmmerContext):Void;
  function build(ctx:AmmerContext):Array<String>;
  function patch(ctx:AmmerContext):Void;
}
