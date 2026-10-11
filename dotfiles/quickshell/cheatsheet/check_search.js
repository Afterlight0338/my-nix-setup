// node check_search.js — sanity checks for search.js
const fs = require("fs"), vm = require("vm"), assert = require("assert");
const ctx = {};
vm.runInNewContext(fs.readFileSync(__dirname + "/search.js", "utf8") + ";this.filter = filter", ctx);

const groups = [
    { name: "Window Actions", items: [
        { label: "Window decrease width", keys: [["Super", "-"]] },
        { label: "Resize window", keys: [["Super", "X"]] },
        { label: "Close window", keys: [["Super", "Q"]] },
    ] },
    { name: "Apps", items: [{ label: "Audio settings", keys: [["Ctrl", "Alt", "V"]] }] },
    { name: "Media", items: [{ label: "Volume mute", keys: [["Super", "Shift", "M"]] }] },
    { name: "Launcher commands", items: [{ label: "Wallpaper carousel", keys: [[">wallpaper"]] }, { label: "Calculator (Qalc)", keys: [[">calc 2+2"]] }] },
    { name: "Other", items: [
        { label: "Drag / resize window", keys: [["Super", "LMB"]] },
        { label: "Kill shell", keys: [["Ctrl", "Super", "Shift", "R"]] },
    ] },
];
const best = q => ctx.filter(groups, q).best?.item.label;
const labels = q => ctx.filter(groups, q).groups.flatMap(g => g.items.map(i => i.label));

assert.equal(best("settings"), "Audio settings");
assert.equal(best("resize"), "Resize window");
assert.ok(labels("resize").includes("Window decrease width"), "synonym: resize -> width");
assert.ok(labels("resi").includes("Window decrease width"), "synonym while still typing");
assert.equal(best("clse"), "Close window", "typo");
assert.equal(best("kill window"), "Close window", "multi-word + synonym");
assert.equal(best("sound"), "Volume mute");
assert.equal(best("q"), "Close window", "key match");
assert.equal(best("zzzz"), undefined);
assert.equal(ctx.filter(groups, "  ").groups.length, groups.length, "empty query shows everything");
assert.equal(best("background"), "Wallpaper carousel", "synonym into launcher commands");
assert.equal(best("math"), "Calculator (Qalc)");
console.log("ok");
