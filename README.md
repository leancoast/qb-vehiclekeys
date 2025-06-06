# qb-vehiclekeys
Ox_inventory için metada araç anahtarı sistemi.

Gereklilikler:

ox_lib
ox_inventory
ox_target

![vehiclekey](https://github.com/user-attachments/assets/4fe2a09a-8a92-4a34-b2cd-9108ab8e3a3b)

Görseli ox_inventory/web/images içerisine atınız.

ox_inventory/data/items kısmna ise bu itemi ekleyin:


	['vehiclekey'] = {
		label = 'Araç Anahtarı',
		weight = 1,
		stack = false,
		description = 'A key for a vehicle with plate: %s',
		client = {
			allowDrop = true,
			allowTransfer = true
		}
	},


Sadece bunları yapmanız yeterli. Artık anahtar sisteminiz otomatik olarak metada'ya geçti.
