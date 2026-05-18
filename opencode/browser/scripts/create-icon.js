const fs = require('fs');
const path = require('path');

const zlib = require('zlib');

function createPNG(width, height, r, g, b) {
  const signature = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);

  function makeChunk(type, data) {
    const typeBuf = Buffer.from(type);
    const combined = Buffer.concat([typeBuf, data]);
    let crc = 0xffffffff;
    for (let i = 0; i < combined.length; i++) {
      crc ^= combined[i];
      for (let j = 0; j < 8; j++) {
        crc = (crc >>> 1) ^ (crc & 1 ? 0xedb88320 : 0);
      }
    }
    crc = (crc ^ 0xffffffff) >>> 0;
    const crcBuf = Buffer.alloc(4);
    crcBuf.writeUInt32BE(crc, 0);
    const lenBuf = Buffer.alloc(4);
    lenBuf.writeUInt32BE(data.length, 0);
    return Buffer.concat([lenBuf, typeBuf, data, crcBuf]);
  }

  const ihdrData = Buffer.alloc(13);
  ihdrData.writeUInt32BE(width, 0);
  ihdrData.writeUInt32BE(height, 4);
  ihdrData[8] = 8;
  ihdrData[9] = 2;
  ihdrData[10] = 0;
  ihdrData[11] = 0;
  ihdrData[12] = 0;

  const rawRows = [];
  for (let y = 0; y < height; y++) {
    const row = Buffer.alloc(width * 3 + 1);
    row[0] = 0;
    for (let x = 0; x < width; x++) {
      row[x * 3 + 1] = r;
      row[x * 3 + 2] = g;
      row[x * 3 + 3] = b;
    }
    rawRows.push(row);
  }
  const raw = Buffer.concat(rawRows);
  const idatData = zlib.deflateSync(raw);

  return Buffer.concat([
    signature,
    makeChunk('IHDR', ihdrData),
    makeChunk('IDAT', idatData),
    makeChunk('IEND', Buffer.alloc(0)),
  ]);
}

const png = createPNG(256, 256, 233, 69, 96);
fs.writeFileSync(path.join(__dirname, 'icon.png'), png);
console.log('Created icon.png (256x256)');
