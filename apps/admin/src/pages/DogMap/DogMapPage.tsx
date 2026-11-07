import { useCallback, useEffect, useMemo, useRef, useState, type PointerEvent, type WheelEvent } from 'react'
import { useAsyncData } from '../../hooks/useAsyncData'
import { adminRepository } from '../../services/adminRepository'

type LocatedDog = Awaited<ReturnType<typeof adminRepository.dogsWithLocations>>[number]
type MapView = { latitude: number; longitude: number; zoom: number }
const minZoom = 3, maxZoom = 19
const clamp = (value: number, minimum: number, maximum: number) => Math.min(Math.max(value, minimum), maximum)
const worldSize = (zoom: number) => 256 * 2 ** zoom
function project(latitude: number, longitude: number, zoom: number) { const size = worldSize(zoom), safeLatitude = clamp(latitude, -85.05112878, 85.05112878), x = (longitude + 180) / 360 * size, radians = safeLatitude * Math.PI / 180, y = (1 - Math.asinh(Math.tan(radians)) / Math.PI) / 2 * size; return { x, y } }
function unproject(x: number, y: number, zoom: number) { const size = worldSize(zoom), longitude = x / size * 360 - 180, n = Math.PI - 2 * Math.PI * y / size; return { latitude: 180 / Math.PI * Math.atan(Math.sinh(n)), longitude: ((longitude + 540) % 360) - 180 } }
function locationDate(value: string) { return new Date(value).toLocaleString('tr-TR') }

export function DogMapPage() {
  const q = useAsyncData(useCallback(() => adminRepository.dogsWithLocations(), []))
  const [selectedID, setSelectedID] = useState<string | null>(null)
  const located = useMemo(() => q.data?.filter(item => item.location) ?? [], [q.data])
  const selected = q.data?.find(item => item.dog.id === selectedID) ?? located[0] ?? null
  useEffect(() => { if (!selectedID && located[0]) setSelectedID(located[0].dog.id) }, [located, selectedID])
  return <section className="panel dog-map-page"><div className="panel-title"><div><h2>Köpek Haritası</h2><p>Yayınlanmış son konumlar gösterilir; canlı takip değildir.</p></div><button onClick={() => void q.refresh()} disabled={q.loading}>Yenile</button></div>{q.loading ? <p className="loading">Köpek konumları yükleniyor…</p> : q.error ? <div className="empty">{q.error}</div> : !q.data?.length ? <div className="empty">Gösterilecek köpek bulunmuyor.</div> : <div className="dog-map-layout"><DogList dogs={q.data} selectedID={selectedID} onSelect={setSelectedID} /><div>{located.length ? <LocationMap dogs={located} selected={selected?.location ? selected : located[0]} selectedID={selectedID} onSelect={setSelectedID} /> : <div className="empty map-empty">Konum bilgisi olan köpek bulunmuyor.</div>}{selected?.location ? <section className="map-details"><strong>{selected.dog.name}</strong><span>Son konum: {selected.location.latitude.toFixed(6)}, {selected.location.longitude.toFixed(6)}</span><span>Yayınlanma zamanı: {locationDate(selected.location.updated_at)}</span></section> : selected && <section className="map-details"><strong>{selected.dog.name}</strong><span>Konum bilgisi yok.</span></section>}</div></div>}</section>
}

function DogList({ dogs, selectedID, onSelect }: { dogs: LocatedDog[]; selectedID: string | null; onSelect: (id: string) => void }) { return <aside className="dog-map-list" aria-label="Köpek listesi">{dogs.map(item => <button key={item.dog.id} className={item.dog.id === selectedID ? 'selected' : ''} onClick={() => onSelect(item.dog.id)}><strong>{item.dog.name}</strong><small>{item.location ? 'Son konum: ' + locationDate(item.location.updated_at) : 'Konum bilgisi yok'}</small></button>)}</aside> }

function LocationMap({ dogs, selected, selectedID, onSelect }: { dogs: LocatedDog[]; selected: LocatedDog; selectedID: string | null; onSelect: (id: string) => void }) {
  const mapRef = useRef<HTMLDivElement>(null)
  const pointers = useRef(new Map<number, { x: number; y: number }>())
  const dragStart = useRef<{ x: number; y: number; center: { x: number; y: number } } | null>(null)
  const pinch = useRef<{ distance: number; zoom: number } | null>(null)
  const [size, setSize] = useState({ width: 768, height: 420 })
  const [dragging, setDragging] = useState(false)
  const [view, setView] = useState<MapView>({ latitude: selected.location!.latitude, longitude: selected.location!.longitude, zoom: 16 })
  useEffect(() => { setView(current => ({ ...current, latitude: selected.location!.latitude, longitude: selected.location!.longitude })) }, [selected.dog.id, selected.location])
  useEffect(() => { if (!mapRef.current) return; const observer = new ResizeObserver(([entry]) => setSize({ width: entry.contentRect.width, height: entry.contentRect.height })); observer.observe(mapRef.current); return () => observer.disconnect() }, [])
  const center = project(view.latitude, view.longitude, view.zoom)
  const tiles = useMemo(() => {
    const tileX = Math.floor(center.x / 256), tileY = Math.floor(center.y / 256), horizontal = Math.ceil(size.width / 512) + 1, vertical = Math.ceil(size.height / 512) + 1, limit = 2 ** view.zoom
    return Array.from({ length: vertical * 2 + 1 }, (_, row) => row - vertical).flatMap(offsetY => Array.from({ length: horizontal * 2 + 1 }, (_, column) => column - horizontal).map(offsetX => {
      const rawX = tileX + offsetX, y = tileY + offsetY
      return y < 0 || y >= limit ? null : { x: ((rawX % limit) + limit) % limit, y, key: rawX + '-' + y, left: size.width / 2 + offsetX * 256 - (center.x % 256), top: size.height / 2 + offsetY * 256 - (center.y % 256) }
    }).filter((tile): tile is { x: number; y: number; key: string; left: number; top: number } => Boolean(tile)))
  }, [center.x, center.y, size.height, size.width, view.zoom])
  const offsets = (dog: LocatedDog) => { const samePlace = dogs.filter(item => item.location?.latitude === dog.location?.latitude && item.location?.longitude === dog.location?.longitude), index = samePlace.findIndex(item => item.dog.id === dog.dog.id); if (samePlace.length < 2) return { x: 0, y: 0 }; const angle = index / samePlace.length * Math.PI * 2 - Math.PI / 2; return { x: Math.cos(angle) * 22, y: Math.sin(angle) * 22 } }
  const changeZoom = (change: number) => setView(current => ({ ...current, zoom: clamp(current.zoom + change, minZoom, maxZoom) }))
  const pointerDistance = () => { const [first, second] = [...pointers.current.values()]; return first && second ? Math.hypot(first.x - second.x, first.y - second.y) : 0 }
  function onPointerDown(event: PointerEvent<HTMLDivElement>) { event.currentTarget.setPointerCapture(event.pointerId); pointers.current.set(event.pointerId, { x: event.clientX, y: event.clientY }); if (pointers.current.size === 1) { dragStart.current = { x: event.clientX, y: event.clientY, center }; setDragging(true) } else if (pointers.current.size === 2) { pinch.current = { distance: pointerDistance(), zoom: view.zoom }; dragStart.current = null } }
  function onPointerMove(event: PointerEvent<HTMLDivElement>) { if (!pointers.current.has(event.pointerId)) return; pointers.current.set(event.pointerId, { x: event.clientX, y: event.clientY }); if (pointers.current.size === 2 && pinch.current) { const distance = pointerDistance(); if (distance > 0) setView(current => ({ ...current, zoom: clamp(pinch.current!.zoom + Math.log2(distance / pinch.current!.distance), minZoom, maxZoom) })); return } if (pointers.current.size === 1 && dragStart.current) { const start = dragStart.current, next = unproject(start.center.x - (event.clientX - start.x), start.center.y - (event.clientY - start.y), view.zoom); setView(current => ({ ...current, ...next })) } }
  function onPointerEnd(event: PointerEvent<HTMLDivElement>) { pointers.current.delete(event.pointerId); if (pointers.current.size < 2) pinch.current = null; if (pointers.current.size === 1) { const only = [...pointers.current.values()][0]; dragStart.current = { x: only.x, y: only.y, center: project(view.latitude, view.longitude, view.zoom) } } else { dragStart.current = null; setDragging(false) } }
  function onWheel(event: WheelEvent<HTMLDivElement>) { event.preventDefault(); changeZoom(event.deltaY < 0 ? 1 : -1) }
  return <div ref={mapRef} className={dragging ? 'dog-map is-dragging' : 'dog-map'} aria-label="Köpek konum haritası" onPointerDown={onPointerDown} onPointerMove={onPointerMove} onPointerUp={onPointerEnd} onPointerCancel={onPointerEnd} onWheel={onWheel}>{tiles.map(tile => <img key={tile.key} src={'https://tile.openstreetmap.org/' + view.zoom + '/' + tile.x + '/' + tile.y + '.png'} alt="" style={{ left: tile.left, top: tile.top }} />)}{dogs.map(item => { const point = project(item.location!.latitude, item.location!.longitude, view.zoom), offset = offsets(item); return <button key={item.dog.id} className={item.dog.id === selectedID ? 'map-marker selected' : 'map-marker'} style={{ left: size.width / 2 + point.x - center.x + offset.x, top: size.height / 2 + point.y - center.y + offset.y }} onPointerDown={event => event.stopPropagation()} onClick={() => onSelect(item.dog.id)} aria-label={item.dog.name + ' konumunu seç'}><span>🐾</span><small>{item.dog.name}</small></button> })}<div className="map-controls" aria-label="Harita yakınlaştırma kontrolleri"><button type="button" onPointerDown={event => event.stopPropagation()} onClick={() => changeZoom(1)} disabled={view.zoom >= maxZoom} aria-label="Yakınlaştır">+</button><button type="button" onPointerDown={event => event.stopPropagation()} onClick={() => changeZoom(-1)} disabled={view.zoom <= minZoom} aria-label="Uzaklaştır">−</button></div></div>
}
