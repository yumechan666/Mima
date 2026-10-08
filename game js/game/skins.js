const sheets = (prefix) => ({
  basic: `${prefix}_BASIC`,
  air: `${prefix}_AIR`,
  tree: `${prefix}_TREE`,
  traversalOne: `${prefix}_TRAVERSAL_ONE`,
  traversalTwo: `${prefix}_TRAVERSAL_TWO`,
  abilities: `${prefix}_ABILITIES`,
  conditions: `${prefix}_CONDITIONS`,
  interactions: `${prefix}_INTERACTIONS`,
});

export const SKINS = [
  {
    id: "classic",
    name: "Mima Klasik",
    swatch: ["#8e8c84", "#6f8d62", "#b9874d"],
    sheets: {
      basic: "MIMA_BASIC_SHEET",
      air: "MIMA_AIR_SHEET",
      tree: "MIMA_TREE_SHEET",
      traversalOne: "MIMA_TRAVERSAL_ONE_SHEET",
      traversalTwo: "MIMA_TRAVERSAL_TWO_SHEET",
      abilities: "MIMA_ABILITIES_SHEET",
      conditions: "MIMA_CONDITIONS_SHEET",
      interactions: "MIMA_INTERACTIONS_SHEET",
    },
  },
  { id: "moon-dew", name: "Embun Bulan", swatch: ["#d6d5df", "#536f9b", "#a792bf"], sheets: sheets("SKIN_02") },
  { id: "ember-keeper", name: "Penjaga Bara", swatch: ["#4c4b4b", "#db6b38", "#a56b3d"], sheets: sheets("SKIN_03") },
  { id: "mist-current", name: "Arus Kabut", swatch: ["#7795a0", "#37a9aa", "#487f75"], sheets: sheets("SKIN_04") },
  { id: "crystal-root", name: "Akar Kristal", swatch: ["#465168", "#53d6d1", "#7963a7"], sheets: sheets("SKIN_05") },
  { id: "canopy-silk", name: "Sutra Kanopi", swatch: ["#dfd0b8", "#a98ab9", "#684d70"], sheets: sheets("SKIN_06") },
  { id: "termite-terra", name: "Terra Rayap", swatch: ["#a85f43", "#c3983e", "#8d4a32"], sheets: sheets("SKIN_07") },
  { id: "storm-peak", name: "Puncak Badai", swatch: ["#d8dde0", "#344e70", "#687e91"], sheets: sheets("SKIN_08") },
  { id: "camp-rescuer", name: "Penyelamat Kamp", swatch: ["#444d54", "#a64f3b", "#3f7b78"], sheets: sheets("SKIN_09") },
  { id: "baobab-gold", name: "Emas Baobab", swatch: ["#d4a957", "#24766d", "#5b3d2c"], sheets: sheets("SKIN_10") },
];

const LEGACY_TO_SLOT = {
  MIMA_BASIC_SHEET: "basic",
  MIMA_AIR_SHEET: "air",
  MIMA_TREE_SHEET: "tree",
  MIMA_TRAVERSAL_ONE_SHEET: "traversalOne",
  MIMA_TRAVERSAL_TWO_SHEET: "traversalTwo",
  MIMA_ABILITIES_SHEET: "abilities",
  MIMA_CONDITIONS_SHEET: "conditions",
  MIMA_INTERACTIONS_SHEET: "interactions",
};

export function skinAssetKey(skin, legacyKey) {
  return skin?.sheets?.[LEGACY_TO_SLOT[legacyKey]] ?? legacyKey;
}

export function skinKeys(skin) {
  return Object.values(skin.sheets);
}
