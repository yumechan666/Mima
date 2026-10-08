const fs = require('fs');
const dir = process.argv[2];
const skins = ['02','03','04','05','06','07','08','09','10'];
for (const s of skins) {
  const f = `${dir}/skin_${s}_basic-transparent.webp`;
  const buf = fs.readFileSync(f);
  const fourcc = (o) => buf.toString('ascii', o, o+4);
  if (fourcc(0)!=='RIFF' || fourcc(8)!=='WEBP') { console.log(`skin_${s}: NOT WEBP`); continue; }
  const chunks = [];
  let off = 12;
  let w=null,h=null,flags=null;
  while (off + 8 <= buf.length) {
    const cc = fourcc(off);
    const size = buf.readUInt32LE(off+4);
    const payload = off+8;
    if (cc==='VP8X') {
      flags = buf[off+8];
      w = (buf[off+8+4] | (buf[off+8+5]<<8) | (buf[off+8+6]<<16)) + 1;
      h = (buf[off+8+7] | (buf[off+8+8]<<8) | (buf[off+8+9]<<16)) + 1;
    }
    chunks.push(cc);
    off = payload + size + (size & 1);
  }
  const alpha = flags!=null ? (flags & 0x10 ? 1:0) : '?';
  console.log(`skin_${s}: chunks=[${chunks.join(',')}] dim=${w}x${h} alphaFlag=${alpha}`);
}
