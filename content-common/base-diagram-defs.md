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
      .code {
        font-family: "JetBrainsMono", monospace;
      }
      .join {
        fill: none;
        marker-end: url(#arrow);
        stroke: #444;
        stroke-width: 1px;
      }
      .etc {
        stroke: #aaa;
      }
      .join.etc {
        marker-end: url(#arrow-etc);
      }
    </style>
    <marker id="arrow" viewBox="0 0 10 10" refX="5" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path fill="#444" d="M 0 0 L 10 5 L 0 10 z" />
    </marker>
    <marker id="arrow-etc" viewBox="0 0 10 10" refX="5" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path fill="#aaa" d="M 0 0 L 10 5 L 0 10 z" />
    </marker>
  </defs>