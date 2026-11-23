// Fictional recipients used by the demo. Every company name here is invented;
// cities are real places so the data reads naturally.
//
// Shared by the app (labels, task form) and by scripts/seed.ts, so it must
// stay free of imports and of non-erasable TypeScript syntax.

export type RecipientBuilding = "PJ01" | "FG01"

export interface Recipient {
  code: string
  name: string
  city: string
  country: string
  building: RecipientBuilding
  /** Highlight colour for key accounts in the Backoffice and dashboards. */
  accent?: "rose" | "blue"
}

export const RECIPIENTS: Recipient[] = [
  // PJ01 — clinical / laboratory recipients (non-commercial flows)
  { code: "VERCORS", name: "Laboratoires Vercors", city: "Grenoble", country: "FR", building: "PJ01", accent: "blue" },
  { code: "NOVALIS", name: "Novalis Biotech", city: "Lyon", country: "FR", building: "PJ01", accent: "rose" },
  { code: "ALDREN", name: "Aldren Pharma", city: "Basel", country: "CH", building: "PJ01" },
  { code: "BRIGHTMOOR", name: "Brightmoor Diagnostics", city: "Manchester", country: "UK", building: "PJ01" },
  { code: "CASTELVIO", name: "Castelvio Farmaceutici", city: "Milan", country: "IT", building: "PJ01" },
  { code: "DUNMORE", name: "Dunmore Clinical Supplies", city: "Dublin", country: "IE", building: "PJ01" },
  { code: "ELSBETH", name: "Elsbeth Analytik", city: "Hamburg", country: "DE", building: "PJ01" },
  { code: "FERROVALE", name: "Ferrovale Life Sciences", city: "Porto", country: "PT", building: "PJ01" },
  { code: "GLENHAVEN", name: "Glenhaven Bioservices", city: "Edinburgh", country: "UK", building: "PJ01" },
  { code: "HALVORSEN", name: "Halvorsen Biolab", city: "Oslo", country: "NO", building: "PJ01" },
  { code: "ISARWERK", name: "Isarwerk Pharma", city: "Munich", country: "DE", building: "PJ01" },
  { code: "JADEPORT", name: "Jadeport Therapeutics", city: "Boston", country: "US", building: "PJ01" },
  { code: "KESTRELRIDGE", name: "Kestrel Ridge Labs", city: "Raleigh", country: "US", building: "PJ01" },
  { code: "LINDQVIST", name: "Lindqvist Medtech", city: "Gothenburg", country: "SE", building: "PJ01" },
  { code: "SOLMAR", name: "Solmar Biociencias", city: "Valencia", country: "ES", building: "PJ01" },
  { code: "NORDFJELL", name: "Nordfjell Analytica", city: "Bergen", country: "NO", building: "PJ01" },
  { code: "ORVANE", name: "Orvane Biologics", city: "San Diego", country: "US", building: "PJ01" },
  { code: "PELLUCID", name: "Pellucid Assay Systems", city: "Cambridge", country: "UK", building: "PJ01" },
  { code: "RIVAUX", name: "Rivaux Instruments", city: "Toulouse", country: "FR", building: "PJ01" },
  { code: "SABLON", name: "Sablon Pharma", city: "Brussels", country: "BE", building: "PJ01" },
  { code: "TARVISIO", name: "Tarvisio Labs", city: "Turin", country: "IT", building: "PJ01" },
  { code: "ULMENHOF", name: "Ulmenhof Diagnostik", city: "Vienna", country: "AT", building: "PJ01" },
  { code: "ZEPHYRINE", name: "Zephyrine Sciences", city: "Geneva", country: "CH", building: "PJ01" },
  { code: "BELVAUX", name: "Belvaux Analytique", city: "Lausanne", country: "CH", building: "PJ01" },

  // FG01 — commercial distribution (finished goods)
  { code: "QUARRYSTONE", name: "Quarrystone Clinical", city: "Philadelphia", country: "US", building: "FG01" },
  { code: "VALDORA", name: "Valdora Distribución", city: "Madrid", country: "ES", building: "FG01" },
  { code: "WESTBROOK", name: "Westbrook Medical Supply", city: "Chicago", country: "US", building: "FG01" },
  { code: "YSSELMONDE", name: "Ysselmonde Pharma Logistics", city: "Rotterdam", country: "NL", building: "FG01" },
  { code: "ARCWELL", name: "Arcwell Healthcare", city: "Denver", country: "US", building: "FG01" },
  { code: "CORVINA", name: "Corvina Distribuzione", city: "Verona", country: "IT", building: "FG01" },
  { code: "DRUMLIN", name: "Drumlin Medical", city: "Cork", country: "IE", building: "FG01" },
  { code: "ESTRELINHA", name: "Estrelinha Farma", city: "Lisbon", country: "PT", building: "FG01" },
  { code: "FJORDLINE", name: "Fjordline Health", city: "Copenhagen", country: "DK", building: "FG01" },
  { code: "GRANITEVALE", name: "Granitevale Pharma", city: "Seattle", country: "US", building: "FG01" },
  { code: "HOLLINGMAAS", name: "Hollinger & Maas Groothandel", city: "Utrecht", country: "NL", building: "FG01" },
  { code: "INVERLEITH", name: "Inverleith Pharma Wholesale", city: "Glasgow", country: "UK", building: "FG01" },
]

const BY_CODE = new Map(RECIPIENTS.map((r) => [r.code, r]))

export function findRecipient(code: string | null | undefined): Recipient | undefined {
  return code ? BY_CODE.get(code) : undefined
}

export function recipientLabel(code: string | null | undefined): string | null {
  if (!code) return null
  const r = BY_CODE.get(code)
  return r ? `${r.name} — ${r.city} (${r.country})` : code
}
