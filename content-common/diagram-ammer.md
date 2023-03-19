<svg viewBox="-20 0 680 283" preserveAspectRatio="xMidYMid slice" role="img">
  <title>Diagram: ammer overview</title>
  <defs>
    <style>
      .box {
        fill: none;
        height: 50px;
        stroke: #444;
        stroke-width: 1px;
        width: 100px;
      }
      .box-text {
        fill: #444;
        font-size: 1.4rem;
        font-family: "Open Sans", sans-serif;
        height: 50px;
        text-anchor: middle;
        width: 100px;
      }
      .join {
        fill: none;
        marker-end: url(#arrow);
        stroke: #444;
        stroke-width: 1px;
      }
      .join-shade {
        fill: none;
        stroke: rgba(255, 255, 255, .8);
        //#fff;
        stroke-width: 5px;
      }
      .etc {
        stroke: #aaa;
      }
      .join.etc {
        marker-end: url(#arrow-etc);
      }
      .group {
        fill: none;
        stroke: #a00;
        stroke-width: 3px;
      }
      .group-text {
        font-size: 1.4rem;
        font-family: "Open Sans", sans-serif;
        text-anchor: middle;
      }
      .code {
        font-family: "JetBrainsMono", monospace;
      }
    </style>
    <marker id="arrow" viewBox="0 0 10 10" refX="5" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path fill="#444" d="M 0 0 L 10 5 L 0 10 z" />
    </marker>
    <marker id="arrow-etc" viewBox="0 0 10 10" refX="5" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path fill="#aaa" d="M 0 0 L 10 5 L 0 10 z" />
    </marker>
  </defs>
<!-- - -->
  <g transform="translate(375,1)">
    <rect class="group" x="0.5" y="0.5" width="130" height="280" />
    <text class="group-text code" x="65" y="270">ammer</text>
  </g>
<!-- - -->
  <g transform="translate(0,16)">
    <rect class="box" x="0.5" y="90.5" /><text class="box-text" x="50" y="120">Haxe code</text>
    <path d="M 100 115.5 h 14.5 v +90 h 13.5" class="join etc" />
    <path d="M 100 115.5 h 14.5 v +30 h 13.5" class="join" />
    <path d="M 100 115.5 h 14.5 v -30 h 13.5" class="join" />
    <path d="M 100 115.5 h 14.5 v -90 h 13.5" class="join" />
  </g>
<!-- - -->
  <g transform="translate(130,16)">
    <rect class="box" x="0.5" y="0.5" /><text class="box-text" x="50" y="30">C++</text>
    <rect class="box" x="0.5" y="60.5" /><text class="box-text" x="50" y="90">HashLink</text>
    <rect class="box" x="0.5" y="120.5" /><text class="box-text" x="50" y="150">Java</text>
    <rect class="box etc" x="0.5" y="180.5" /><text class="box-text etc" x="50" y="210">...</text>
    <line x1="100" y1="25.5" x2="128" y2="25.5" class="join" />
    <line x1="100" y1="85.5" x2="128" y2="85.5" class="join" />
    <line x1="100" y1="145.5" x2="128" y2="145.5" class="join" />
    <line x1="100" y1="205.5" x2="128" y2="205.5" class="join etc" />
  </g>
<!-- - -->
  <g transform="translate(260,16)">
    <line x1="100" y1="25.5" x2="128" y2="25.5" class="join-shade" />
    <line x1="100" y1="85.5" x2="128" y2="85.5" class="join-shade" />
    <line x1="100" y1="145.5" x2="128" y2="145.5" class="join-shade" />
    <line x1="100" y1="205.5" x2="128" y2="205.5" class="join-shade" />
    <rect class="box" x="0.5" y="0.5" /><text class="box-text" x="50" y="30">hxcpp</text>
    <rect class="box" x="0.5" y="60.5" /><text class="box-text" x="50" y="90">HL runtime</text>
    <rect class="box" x="0.5" y="120.5" /><text class="box-text" x="50" y="150">JVM</text>
    <rect class="box etc" x="0.5" y="180.5" /><text class="box-text etc" x="50" y="210">...</text>
    <line x1="100" y1="25.5" x2="128" y2="25.5" class="join" />
    <line x1="100" y1="85.5" x2="128" y2="85.5" class="join" />
    <line x1="100" y1="145.5" x2="128" y2="145.5" class="join" />
    <line x1="100" y1="205.5" x2="128" y2="205.5" class="join etc" />
  </g>
<!-- - -->
  <g transform="translate(390,16)">
    <line x1="100" y1="25.5" x2="128" y2="25.5" class="join-shade" />
    <line x1="100" y1="85.5" x2="128" y2="85.5" class="join-shade" />
    <line x1="100" y1="145.5" x2="128" y2="145.5" class="join-shade" />
    <line x1="100" y1="205.5" x2="128" y2="205.5" class="join-shade" />
    <rect class="box" x="0.5" y="0.5" /><text class="box-text" x="50" y="30">C externs</text>
    <rect class="box" x="0.5" y="60.5" /><text class="box-text" x="50" y="90">HL FFI</text>
    <rect class="box" x="0.5" y="120.5" /><text class="box-text" x="50" y="150">JNI</text>
    <rect class="box etc" x="0.5" y="180.5" /><text class="box-text etc" x="50" y="210">...</text>
    <path d="M 100 205.5 h 34.5 v -90 h 13.5" class="join etc" />
    <path d="M 100 145.5 h 34.5 v -30 h 13.5" class="join" />
    <path d="M 100  85.5 h 34.5 v +30 h 13.5" class="join" />
    <path d="M 100  25.5 h 34.5 v +90 h 13.5" class="join" />
  </g>
<!-- - -->
  <g transform="translate(540,16)">
    <rect class="box" x="0.5" y="90.5" /><text class="box-text" x="50" y="120">native library</text>
  </g>
</svg>
