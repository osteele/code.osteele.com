// Add class names to elements, so that Semantic UI will style them.
Object.entries({
    h1: "ui header",
    h2: "ui huge header",
    h3: "ui large header",
    h4: "ui header",
    h5: "ui header",
    h6: "ui header",
}).forEach(([tagName, classNames]) =>
    Array.from(document.getElementsByTagName(tagName)).forEach(elt =>
        elt.className += `${elt.className} ${classNames}`.trim()))
