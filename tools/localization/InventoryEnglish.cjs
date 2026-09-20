const fs = require('node:fs');
const path = require('node:path');
function collect(root = path.resolve(__dirname, '../..')) {
const found = new Map();
function add(source, file, location) {
  if (!/[가-힣]/.test(source)) return;
  if (!found.has(source)) found.set(source, {source, locations:[]});
  found.get(source).locations.push(file + ':' + location);
}
function files(directory) {
  return fs.readdirSync(path.join(root,directory), {withFileTypes:true}).flatMap(item => {
    const file = directory + '/' + item.name;
    return item.isDirectory() ? files(file) : [file];
  });
}
function scriptStrings(text, file) {
  let line = 1;
  for (let i = 0; i < text.length; i++) {
    if (text[i] === '\n') { line++; continue; }
    if (text[i] === '#') { while (i < text.length && text[i] !== '\n') i++; line++; continue; }
    if (!['"', "'"].includes(text[i])) continue;
    const quote = text[i], startLine = line;
    const delimiter = text.slice(i, i+3) === quote.repeat(3) ? quote.repeat(3) : quote;
    i += delimiter.length;
    let value = '';
    while (i < text.length && text.slice(i,i+delimiter.length) !== delimiter) {
      if (text[i] === '\n') line++;
      if (text[i] === '\\') {
        i++;
        value += ({n:'\n',r:'\r',t:'\t',b:'\b',f:'\f'})[text[i]] ?? text[i];
      } else value += text[i];
      i++;
    }
    i += delimiter.length-1;
    add(value, file, startLine);
  }
}
function jsonStrings(value, file, pointer='') {
  // These four quarantined asset notes are pre-existing mojibake, never player text.
  if (file === 'data/dungeon_quarter/wall_asset_catalog.json' && /^\/quarantined_legacy_groups\/[^/]+\/reason$/.test(pointer)) return;
  if (typeof value === 'string') add(value,file,pointer);
  else if (Array.isArray(value)) value.forEach((entry,index) => jsonStrings(entry,file,pointer+'/'+index));
  else if (value && typeof value === 'object') for (const [key,entry] of Object.entries(value)) jsonStrings(entry,file,pointer+'/'+key);
}
for (const file of [...files('scripts'), ...files('scenes')].filter(file => file.endsWith('.gd') && !file.endsWith('/EnglishTranslation.gd'))) scriptStrings(fs.readFileSync(path.join(root,file),'utf8'),file);
for (const file of files('data').filter(file => file.endsWith('.json') && !file.startsWith('data/story/') && !file.startsWith('data/localization/'))) {
  jsonStrings(JSON.parse(fs.readFileSync(path.join(root,file),'utf8').replace(/^\uFEFF/,'')),file);
}
for (const file of files('scenes').filter(file => file.endsWith('.tscn'))) {
  const text = fs.readFileSync(path.join(root,file),'utf8');
  for (const match of text.matchAll(/^(?:text|tooltip_text|placeholder_text) = "((?:\\.|[^"\\])*)"/gm)) {
    add(JSON.parse('"'+match[1]+'"'),file,text.slice(0,match.index).split('\n').length);
  }
}
const entries = [...found.values()];
return entries;
}
if (require.main === module) {
const root = path.resolve(__dirname, '../..');
const entries = collect(root);
const output = path.join(root,process.argv[2] || 'tmp/english_work/ui_inventory_complete.json');
fs.mkdirSync(path.dirname(output),{recursive:true});
fs.writeFileSync(output,JSON.stringify(entries,null,2)+'\n');
console.log(JSON.stringify({strings:entries.length,characters:entries.reduce((n,x)=>n+x.source.length,0),output}));
}
module.exports = {collect};
