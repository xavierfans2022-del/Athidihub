const fs = require('fs');
const path = require('path');
const dirs = fs.readdirSync('src');
for (const dir of dirs) {
  const p = path.join('src', dir);
  if (fs.statSync(p).isDirectory()) {
    const files = fs.readdirSync(p);
    for (const f of files) {
      if (f.endsWith('.controller.ts')) {
        let content = fs.readFileSync(path.join(p, f), 'utf8');
        content = content.replace(/\+id/g, 'id');
        fs.writeFileSync(path.join(p, f), content);
      }
    }
  }
}
