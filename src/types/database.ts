export type Building = "K" | "S"

export type TaskStatus = "NEW" | "IN_PROGRESS" | "DONE" | "LATE" | "STANDBY" | "OUT"

export type TaskPriority = 1 | 2 | 3 | 4 | 5

export type TaskType =
  | "ERP_DOCUMENT"
  | "PREP_DRY_ICE"
  | "OTHER_SHIPMENTS"
  | "RE_SUPPLY"
  | "MAINTENANCE"
  | "PICKING"
  | "PACKING"
  | "TRUCK_LOADING"
  | "SHIPMENT"

export type CarrierType =
  | "DHL"
  | "KUEHNE_NAGEL"
  | "WORLD_COURIER"
  | "ESSERS"
  | "DUPERREX"
  | "TNT_FEDEX"
  | "OTHER"

export type DestinationK =
  | "GUIDONIA_IT"
  | "COLERETTO_IT"
  | "MODUGNO_IT"
  | "EUROFINS"
  | "ANGERS_FR"
  | "MALAGA_ES"
  | "WAVRE_BE"
  | "OTHER"

export type DestinationS =
  | "GLG"
  | "SANTA_PALOMBA"
  | "TURKEY"
  | "SWITZERLAND"
  | "USA"
  | "CHINA"
  | "KOREA"
  | "GUIDONIA"
  | "PHARMALOG_KGAA"
  | "OTHER"

export type AppRole = "admin" | "operator"

export type TransportMode = "ROAD" | "AIR" | "SEA"

export type CmrStatus = "IN_WAITING" | "RECEIVED" | "CHECKED_APPROVED" | "TO_BE_MODIFIED" | "MANUAL" | "NA"

export interface Task {
  id: string
  building: Building
  type: TaskType
  status: TaskStatus
  priority: TaskPriority
  erp_document_number: string | null
  carrier: CarrierType | null
  carrier_other: string | null
  destination_k: DestinationK | null
  destination_k_other: string | null
  destination_s: DestinationS | null
  destination_s_other: string | null
  due_date: string
  due_time: string | null
  bottle_count: number | null
  pallet_count: number | null
  package_count: number | null
  dry_ice_carton_count: number | null
  transport_mode: TransportMode | null
  temperature_group: TemperatureGroup | null
  other_shipment_category: OtherShipmentCategory | null
  cmr_status: CmrStatus | null
  k2_reference: string | null
  k2_closed: boolean
  pgi_done: boolean
  notes: string | null
  created_by: string | null
  created_at: string
  updated_at: string
  completed_at: string | null
}

export const STATUS_LABELS: Record<TaskStatus, string> = {
  NEW: "New",
  IN_PROGRESS: "In Progress",
  DONE: "Done",
  LATE: "Late",
  STANDBY: "Standby",
  OUT: "Out",
}

export const PRIORITY_LABELS: Record<TaskPriority, string> = {
  1: "Urgent",
  2: "Before 1 PM",
  3: "End of Day",
  4: "End of Week",
  5: "Next Week",
}

export const PRIORITY_CLASSES: Record<TaskPriority, string> = {
  1: "bg-priority-urgent/15 text-priority-urgent",
  2: "bg-priority-before-1pm/15 text-priority-before-1pm",
  3: "bg-priority-end-of-day/15 text-priority-end-of-day",
  4: "bg-priority-end-of-week/15 text-priority-end-of-week",
  5: "bg-priority-next-week/15 text-priority-next-week",
}

export const TASK_TYPE_LABELS: Record<TaskType, string> = {
  ERP_DOCUMENT: "Shipment (ERP)",
  PREP_DRY_ICE: "Prep Dry Ice",
  OTHER_SHIPMENTS: "Other Shipments",
  RE_SUPPLY: "Re-Supply",
  MAINTENANCE: "Maintenance",
  PICKING: "Picking",
  PACKING: "Packing",
  TRUCK_LOADING: "Truck Loading",
  SHIPMENT: "Shipment",
}

export const TASK_TYPES_BY_BUILDING: Record<Building, TaskType[]> = {
  K: ["ERP_DOCUMENT", "PREP_DRY_ICE", "OTHER_SHIPMENTS", "RE_SUPPLY", "MAINTENANCE"],
  S: ["SHIPMENT", "RE_SUPPLY", "TRUCK_LOADING"],
}

export const CARRIER_LABELS: Record<CarrierType, string> = {
  DHL: "DHL",
  KUEHNE_NAGEL: "Kuehne+Nagel",
  WORLD_COURIER: "World Courier",
  ESSERS: "Essers",
  DUPERREX: "Duperrex",
  TNT_FEDEX: "TNT/FedEx",
  OTHER: "Other",
}

export const DESTINATION_K_LABELS: Record<DestinationK, string> = {
  GUIDONIA_IT: "Guidonia (IT)",
  COLERETTO_IT: "Coleretto (IT)",
  MODUGNO_IT: "Modugno (IT)",
  EUROFINS: "Eurofins",
  ANGERS_FR: "Angers (FR)",
  MALAGA_ES: "Malaga (ES)",
  WAVRE_BE: "Wavre (BE)",
  OTHER: "Other",
}

export const TRANSPORT_MODE_LABELS: Record<TransportMode, string> = {
  ROAD: "Road",
  AIR: "Air",
  SEA: "Sea",
}

export const CMR_STATUS_LABELS: Record<CmrStatus, string> = {
  IN_WAITING: "CMR: Waiting",
  RECEIVED: "CMR: Received",
  CHECKED_APPROVED: "CMR: OK",
  TO_BE_MODIFIED: "CMR: To fix",
  MANUAL: "CMR: Manual",
  NA: "CMR: N/A",
}

export const DESTINATION_S_LABELS: Record<DestinationS, string> = {
  GLG: "GLG",
  SANTA_PALOMBA: "Santa Palomba",
  TURKEY: "Turkey",
  SWITZERLAND: "Switzerland",
  USA: "USA",
  CHINA: "China",
  KOREA: "Korea",
  GUIDONIA: "Guidonia",
  PHARMALOG_KGAA: "Pharmalog KGaA",
  OTHER: "Other",
}

export interface Collaborator {
  id: string
  name: string
  building: Building
  base_capacity: number
  default_percentage: number
  is_active: boolean
  created_at: string
}

export interface CollaboratorAvailability {
  id: string
  collaborator_id: string
  date: string
  percentage: number
}

export interface CapacityForecast {
  id: string
  building: Building
  date: string
  value: number
}

export type UnitType = "BOTTLE" | "PALLET" | "PACKAGE" | "FIXED" | "CARTON"

export type TemperatureGroup = "AMBIENT" | "DRY_ICE" | "MONITORED"

export type OtherShipmentCategory =
  | "CHEMICALS"
  | "DOMESTIC_SHIPMENT"
  | "HARVEST_BAG"
  | "MARTI"
  | "NAVETTE_AUBONNE_VEVEY"
  | "GUITTERS_ERBITUX_DP"
  | "OTHER"

export interface WorkUnitMatrixEntry {
  id: string
  task_type: TaskType
  other_shipment_category: OtherShipmentCategory | null
  carrier: CarrierType | null
  destination_k: DestinationK | null
  destination_s: DestinationS | null
  temperature_group: TemperatureGroup | null
  unit_type: UnitType
  work_unit_value: number
  created_at: string
}

export const TEMPERATURE_GROUP_LABELS: Record<TemperatureGroup, string> = {
  AMBIENT: "Ambient",
  DRY_ICE: "Dry Ice",
  MONITORED: "Monitored",
}

export const OTHER_SHIPMENT_CATEGORY_LABELS: Record<OtherShipmentCategory, string> = {
  CHEMICALS: "Chemicals",
  DOMESTIC_SHIPMENT: "Domestic Shipment",
  HARVEST_BAG: "Harvest Bag",
  MARTI: "Marti",
  NAVETTE_AUBONNE_VEVEY: "Navette Aubonne-Vevey",
  GUITTERS_ERBITUX_DP: "Guitters Erbitux DP",
  OTHER: "Other",
}

export const UNIT_TYPE_LABELS: Record<UnitType, string> = {
  BOTTLE: "Bottles",
  PALLET: "Pallets",
  PACKAGE: "Packages",
}
