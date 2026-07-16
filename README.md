# fd-acikarttirma

FiveM açık arttırma (mezat) scripti. **Qbox / QBCore / ESX** ile otomatik algılayan bir bridge üzerinden çalışır. Araç, benzinlik (işletme) ve item satılabilir; **klasik artan teklif** ve **otomatik (proxy) teklif** desteklenir. Mezat alanında **DUI ekran** güncel ürün ve teklifi, mezatçının elindeki **tabela propu** güncel rakamı gösterir. Kazanana ödül **otomatik teslim** edilir.

## Özellikler

- 🔌 **Framework bağımsız bridge** — qbx_core / qb-core / es_extended otomatik algılanır (`Config.Framework` ile zorlanabilir).
- 🏷️ **Satılabilir türler:** Araç (garaja işlenir), Benzinlik/İşletme (config hook), Item (metadata dahil).
- 🔨 **Teklif türleri:** Klasik artan + otomatik proxy teklif + opsiyonel Anlık Al (buyout).
- 🏦 **Banka teminatı (escrow):** En yüksek teklif sahibinin parası bloke edilir; geçilince/mezat iptalinde iade, kazanınca düşer. Tüm doğrulamalar **server-side**.
- ⏱️ **Anti-snipe:** Son saniyelerde teklif gelirse lot süresi uzar.
- 🎟️ **Fiş item'ı:** Katılım ücretiyle alınan, metadata'lı (mezat no, tarih, ödenen tutar) fiş. Alan girişinde kontrol edilir.
- 🖥️ **İki DUI:** Alandaki büyük ekran + mezatçının elindeki tabela propu (runtime txd).
- 🌐 **React + TypeScript NUI** (Vite ile derlenir).
- 📝 Discord webhook log, SQL kalıcılık, TR/EN dil.

## Bağımlılıklar

- [ox_lib](https://github.com/overextended/ox_lib) (zorunlu)
- [oxmysql](https://github.com/overextended/oxmysql) (zorunlu)
- [ox_inventory](https://github.com/overextended/ox_inventory) (fiş & item için önerilir)
- [ox_target](https://github.com/overextended/ox_target) (fiş noktası için önerilir; yoksa [E] fallback)
- Framework: `qbx_core` **veya** `qb-core` **veya** `es_extended`

## Kurulum

1. Bu klasörü `resources` altına koyun ve `ensure fd-acikarttirma` ekleyin (ox_lib, oxmysql, framework'ten **sonra**).
2. **Veritabanı:** `sql/acikarttirma.sql` dosyasını import edin.
3. **Fiş item'ı:** `installation/ox_inventory_item.lua` içeriğini ox_inventory `data/items.lua` dosyasına ekleyin (varsayılan ad `mezat_fisi`).
4. **Config:** `config.lua` içinde mezatçı job'ı, konum, DUI prop modelleri/koordinatları, ücretler ve teslim hook'larını ayarlayın.
5. **Benzinlik teslimi:** `Config.Delivery.business` fonksiyonunu kendi işletme/management sisteminize bağlayın.

### NUI'yi derleme (kaynağı değiştirirseniz)

NUI derlenmiş çıktı (`html/`) repoda hazır gelir. Kaynağı (`web/`) değiştirirseniz:

```bash
cd web
npm install
npm run build   # -> ../html/ günceller
```

## Kullanım Akışı

1. Mezatçı (yetkili job) `/mezat` komutuyla paneli açar → mezat oluşturur (ad + katılım ücreti).
2. Panelden lotları ekler (araç/benzinlik/item; başlangıç fiyatı = alt limit, min artış, opsiyonel anlık al).
3. Oyuncular alandaki **fiş noktasından** katılım ücretini ödeyip fiş alır (ox_target ya da [E]).
4. Mezatçı "Mezatı Başlat" der → lotlar sırayla açılır. DUI ekran + tabela güncellenir.
5. Katılımcılar `/mezat` ile teklif panelini açar; klasik/otomatik teklif verir ya da anlık alır.
6. Süre dolunca (veya mezatçı "Sonraki Lot" deyince) çekiç iner; kazanana ödül otomatik teslim edilir.

## Telefon Entegrasyonu (opsiyonel)

Duyuru şimdilik komut/panel üzerinden yapılır. Bir telefon app'inden paneli açmak için:

```lua
exports['fd-acikarttirma']:OpenPanel()
```

Server tarafı duyuru bildirimi için `config.lua` → `Config.Phone.notify` hook'unu doldurun.

## Notlar

- Fiş kontrolü giriş bölgesinde uyarı verir; teklif panelini yalnızca fiş sahibi katılımcılar açabilir (asıl kapı budur).
- DUI runtime texture değişimi istemci-lokaldir; script her istemcide tabela/ekran texture'ını yerel olarak günceller.
- Prop modelleri (`Config.Screen`, `Config.SignProp`) sunucunuza göre değiştirilebilir; `txd`/`txn` alanları seçtiğiniz prop'un texture'ıyla eşleşmelidir.
