local Translations = {
    notify = {
        ydhk = 'Bu aracın anahtarı sende yok!',
        pntf = 'Yakında bir araç yok!',
        nonear = 'Anahtarı verecek kimse yakında değil!',
        vlock = 'Araç kilitlendi!',
        vunlock = 'Aracın kilidi açıldı!',
        vlockpick = 'Kapı kilidini açmayı başardın!',
        fvlockpick = 'Anahtarları bulamadın ve sinirlendin!',
        vgkeys = 'Anahtarları teslim ettin.',
        vgetkeys = 'Aracın anahtarlarını aldın!',
        vgetkeys_new = 'Plakası %s olan aracın anahtarını aldın!',
        fpid = 'Oyuncu ID\'si ve plaka bilgilerini doldur!',
        cjackfail = 'Araç çalma başarısız oldu!',
        vehclose = 'Yakında araç yok!',
        no_money = 'Yeterli paran yok!',
        not_owned = 'Bu araç sana ait değil!',
        engine_off = 'Motor kapatıldı.',
        engine_on = 'Motor çalıştırıldı.'
    },
    progress = {
        takekeys = 'Cesetten anahtar alınıyor...',
        hskeys = 'Araç anahtarları aranıyor...',
        acjack = 'Araç çalma deneniyor...',
    },
    info = {
        skeys = '~g~[H]~w~ - Anahtar Ara',
        tlock = 'Araç Kilidini Aç/Kapat',
        palert = 'Araç hırsızlığı devam ediyor. Tür: ',
        engine = 'Motoru Aç/Kapat',
    },
    addcom = {
        givekeys = 'Anahtarları birine teslim et. ID belirtilmezse, en yakın kişiye veya araçtaki herkese verir.',
        givekeys_id = 'id',
        givekeys_id_help = 'Oyuncu ID\'si',
        addkeys = 'Birine araç için anahtar ekler.',
        addkeys_id = 'id',
        addkeys_id_help = 'Oyuncu ID\'si',
        addkeys_plate = 'plaka',
        addkeys_plate_help = 'Plaka',
        rkeys = 'Birinden araç anahtarını kaldırır.',
        rkeys_id = 'id',
        rkeys_id_help = 'Oyuncu ID\'si',
        rkeys_plate = 'plaka',
        rkeys_plate_help = 'Plaka',
    },
    items = {
        vehiclekey_desc = 'Plakası %s olan bir araç için anahtar',
    }
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})