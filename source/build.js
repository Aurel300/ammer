const fs = require("fs");
const marked = require("marked");
const nunjucks = require("nunjucks");

function commentParse(text) {
  text = text.trim();
  if (!text.startsWith("<!--") || !text.endsWith("-->"))
    return [null, null];
  text = text.substr("<!--".length);
  text = text.substr(0, text.length - "-->".length);
  let split = text.split(":");
  return [split[0], split.slice(1).join(":")];
}

function parse(dir) {
  const menu = {sub: [], depth: 0};
  const pages = [];
  const labels = [];

  let currentMenu = menu;
  let currentPage = null;
  let nextTitle = null;
  let nextLabel = null;
  let nextSublabel = null;

  for (let md of fs.readdirSync(dir)) {
    if (!md.endsWith(".md"))
      continue;
    let tokens = marked.lexer(fs.readFileSync(`${dir}/${md}`, "utf8"));
    let firstHeading = true;
    for (let token of tokens) {
      if (token.type === "html") {
        let [command, arg] = commentParse(token.text);
        switch (command) {
        case "menu":
          nextTitle = arg;
          continue;
          break;
        case "label":
          nextLabel = arg;
          continue;
          break;
        case "sublabel":
          nextSublabel = arg;
          continue;
          break;
        }
      } else if (token.type === "heading") {
        if (nextLabel !== null) {
          if (firstHeading)
            currentMenu = menu;
          while (token.depth <= currentMenu.depth) {
            currentMenu = currentMenu.parent;
          }
          if (nextTitle === null)
            nextTitle = token.text;
          pages.push(labels[nextLabel] = currentPage = {file: md, label: nextLabel, title: nextTitle, tokens: []});
          currentPage.tokens.links = Object.create(null);
          currentMenu.sub.push(currentMenu = {
            title: nextTitle,
            label: nextLabel,
            sub: [],
            parent: currentMenu,
            depth: firstHeading ? 1 : token.depth
          });
          nextTitle = null;
          nextLabel = null;
          firstHeading = false;
          token.depth = 2;
        }
        if (nextSublabel !== null) {
          token.text = `SUB:${nextSublabel}:${token.text}`;
          nextSublabel = null;
        }
      }
      currentPage.tokens.push(token);
    }
  }

  return {menu, pages, labels};
}

function render({menu, pages, labels}, dir) {
  // marked
  const options = {
    langPrefix: "language-"
  };
  const renderer = new marked.Renderer(options);
  const parser = new marked.Parser({
    renderer: renderer,
    ...options
  });

  renderer.link = (href, title, text) => {
    let anchor = href.split("#");
    let ext = false;
    if (href.startsWith("issue:")) {
      href = "https://github.com/Aurel300/ammer/issues/" + href.substr("issue:".length);
      ext = true;
    } else if (href.startsWith("repo:")) {
      if (href.endsWith("/")) {
        href = "https://github.com/Aurel300/ammer/tree/master/" + href.substr("repo:".length);
      } else {
        href = "https://github.com/Aurel300/ammer/blob/master/" + href.substr("repo:".length);
      }
      ext = true;
    } else if (href.startsWith("api:")) {
      href = "https://api.haxe.org/" + href.substr("api:".length);
      ext = true;
    } else if (labels.hasOwnProperty(anchor[0])) {
      title = labels[anchor[0]].title;
      if (anchor.length > 1) {
        href = `${anchor[0]}.html#${anchor[1]}`;
      } else {
        href += ".html";
      }
    } else if (!href.startsWith("http://") && !href.startsWith("https://")) {
      throw `invalid link ${href} (missing reference?)`;
    } else {
      ext = true;
    }
    return `<a href="${href}"${title ? ` title="${title}"` : ""}${ext ? ' target="_blank"' : ""}>${text}</a>`;
  };
  renderer.heading = (text, level, raw, slugger) => {
    let subLabel = null;
    if (text.startsWith("SUB:")) {
      let split = text.split(":");
      text = split.slice(2).join(":");
      subLabel = split[1];
    }
    return `<h${level}${subLabel !== null ? ` id="${subLabel}"` : ""}>${text}</h${level}>`;
  };
  // TODO: highlighter

  // nunjucks
  let flatMenu = "";
  function flattenMenu(menu) {
    flatMenu += `<ul><li><a href="${menu.label}.html">${menu.title}</a></li>`;
    menu.sub.forEach(flattenMenu);
    flatMenu += "</ul>";
  }
  menu.sub.forEach(flattenMenu);

  for (let i = 0; i < pages.length; i++) {
    let {file, label, title, tokens} = pages[i];
    console.log(label, title);
    let content = parser.parse(tokens);
    let context = {
      flatMenu, label, title, content,
      contribute: "https://github.com/Aurel300/ammer/blob/gh-pages/source/content/" + file
    };
    if (i > 0)
      context.prev = {link: `${pages[i - 1].label}.html`, title: pages[i - 1].title};
    if (i < pages.length - 1)
      context.next = {link: `${pages[i + 1].label}.html`, title: pages[i + 1].title};
    let html = nunjucks.render("assets/template.html", context);
    fs.writeFileSync(`${dir}/${label}.html`, html);
  }
}

render(parse("content"), "..");
