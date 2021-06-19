function createSections(elt) {
    const parent = elt.parentNode;
    const siblings = Array.from(parent.children);
    siblings.splice(0, siblings.indexOf(elt) + 1);

    const top = document.createElement('section');
    let topLevel = getHeaderLevel(elt);

    const stack = [];
    let currentSection = top;
    currentSection.append(elt);
    let eltId = elt.id;
    elt.removeAttribute('id');
    top.id = eltId;

    while (siblings.length) {
        const e = siblings.shift();
        const sl = getHeaderLevel(e);
        while (topLevel && sl && sl <= topLevel) {
            currentSection = stack.pop();
            topLevel = currentSection && getHeaderLevel(currentSection.children[0]);
        }
        if (!currentSection) {
            siblings.unshift(e);
            break;
        }
        if (sl === topLevel + 1) {
            stack.push(currentSection);
            currentSection = document.createElement('section');
            stack[stack.length - 1].append(currentSection);
            topLevel = sl;
        }
        currentSection.append(e);
    }
    if (siblings.length) {
        parent.insertBefore(top, siblings[0])
    } else {
        parent.append(top);
    }

    function getHeaderLevel(elt) {
        const m = elt.tagName.match(/^h(\d)$/i);
        return m ? Number(m[1]) : null;
    }
}

createSections(document.getElementById('topics'));
