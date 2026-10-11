// Search for the cheat sheet. Plain JS (no QML) so `node check_search.js` can test it.
// Qt's JS engine lacks newer builtins (flat, flatMap, matchAll), so stick to ES2017.
// A bind matches when every query word hits its label (prefix > substring > synonym > 1-letter typo),
// its group name, or one of its keys. The highest score is the "probably what you're looking for" pick.

const synonymGroups = [
    ["resize", "size", "width", "height", "bigger", "smaller", "grow", "shrink"],
    ["close", "kill", "quit", "exit"],
    ["screenshot", "screen", "capture", "snip", "print"],
    ["record", "recording", "video", "capture"],
    ["volume", "mute", "audio", "sound"],
    ["media", "music", "song", "track", "play", "pause"],
    ["monitor", "display", "screen", "output"],
    ["fullscreen", "maximize", "maximise"],
    ["floating", "float", "tile"],
    ["notifications", "notification", "notifs"],
    ["clipboard", "paste", "copy", "history"],
    ["emoji", "emote"],
    ["lock", "unlock"],
    ["sleep", "suspend", "hibernate"],
    ["session", "logout", "power", "shutdown", "reboot"],
    ["launcher", "apps", "run", "menu"],
    ["settings", "config", "preferences", "options"],
    ["workspace", "desktop"],
    ["window", "app"],
    ["move", "send", "throw"],
    ["focus", "switch", "go"],
    ["terminal", "console"],
    ["browser", "web", "internet"],
    ["file", "files", "explorer"],
    ["colour", "color", "picker"],
    ["group", "tab", "tabs"],
    ["wallpaper", "background", "carousel", "wall"],
    ["calculator", "calc", "math"],
    ["scheme", "theme", "colour", "color"],
];

const synonyms = {};
for (const g of synonymGroups)
    for (const w of g)
        synonyms[w] = (synonyms[w] ?? []).concat(g.filter(x => x !== w));

// edit distance <= 1
function within1(a, b) {
    if (Math.abs(a.length - b.length) > 1)
        return false;
    let i = 0, j = 0, edits = 0;
    while (i < a.length && j < b.length) {
        if (a[i] === b[j]) {
            i++;
            j++;
            continue;
        }
        if (++edits > 1)
            return false;
        if (a.length >= b.length)
            i++;
        if (b.length >= a.length)
            j++;
    }
    return edits + (a.length - i) + (b.length - j) <= 1;
}

function tokenScore(t, words, groupWords, keys) {
    if (t.length === 1 && keys.includes(t))
        return 4; // a lone letter is almost always a key lookup ("q" -> Super + Q)
    if (words.some(w => w.startsWith(t)))
        return 3;
    if (words.some(w => w.includes(t)))
        return 2;
    // synonyms of the word, or of any word it's a prefix of ("resi" -> resize -> width...)
    const syns = t.length >= 3 ? [].concat(...Object.keys(synonyms).filter(k => k.startsWith(t)).map(k => synonyms[k].concat(k))) : synonyms[t] ?? [];
    if (syns.some(s => words.some(w => w.startsWith(s))))
        return 1.5;
    if (t.length >= 4 && words.some(w => within1(t, w) || within1(t, w.slice(0, t.length))))
        return 1;
    if (groupWords.some(w => w.startsWith(t)) || keys.includes(t))
        return 1;
    return 0;
}

function score(item, groupName, query) {
    const words = item.label.toLowerCase().split(/[\s/-]+/);
    const groupWords = groupName.toLowerCase().split(/\s+/);
    const keys = [].concat(...item.keys).map(k => k.toLowerCase());
    let total = 0;
    for (const t of query.toLowerCase().split(/\s+/).filter(Boolean)) {
        const s = tokenScore(t, words, groupWords, keys);
        if (!s)
            return 0;
        total += s;
    }
    return total;
}

// Returns { best: {item, group} | null, groups: [{name, items}] } with non-matching binds removed
function filter(groups, query) {
    if (!query.trim())
        return { best: null, groups };
    let best = null;
    const out = [];
    for (const g of groups) {
        const items = [];
        for (const item of g.items) {
            const s = score(item, g.name, query);
            if (!s)
                continue;
            items.push(item);
            if (!best || s > best.s || (s === best.s && item.label.length < best.item.label.length))
                best = { s, item, group: g.name };
        }
        if (items.length)
            out.push({ name: g.name, items });
    }
    return { best, groups: out };
}
