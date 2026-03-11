# 💾 Nesox Vehicle Persistence

Système de persistance avancée permettant aux joueurs de sauvegarder leurs véhicules n'importe où sur la carte avec une gestion visuelle via `ox_target`.

## ✨ Caractéristiques
* **Sauvegarde Totale** : Enregistre la position exacte, les propriétés de tuning, l'état du moteur, de la carrosserie, du carburant et l'état des pneus.
* **Compatibilité Framework** : Support natif pour **ESX** et **QBCore** avec détection automatique ou manuelle.
* **Gestion d'Inventaire** : Intégration avec `ox_inventory` pour sauvegarder le contenu des coffres et boîtes à gants.
* **Sécurité & OneSync** : Utilise `CreateVehicleServerSetter` pour une création de véhicule côté serveur propre et synchronisée entre tous les joueurs.
* **Interaction Intuitive** : Utilise `ox_target` pour interagir directement avec le véhicule pour activer ou retirer la sauvegarde.

## 🛠️ Installation
1. **Base de données** : Importez le fichier `init.sql` dans votre base de données SQL.
2. **Dépendances** : Ce script nécessite `ox_lib`, `ox_target` et `oxmysql`.
3. Ajoutez `ensure nesox_persistence` à votre `server.cfg`.

## 🚀 Utilisation
1. Approchez-vous d'un véhicule.
2. Utilisez votre menu Target (ALT par défaut).
3. Sélectionnez **"Enregistrer le véhicule"**. Vous devez posséder l'item requis dans votre inventaire.

## ⚙️ Configuration
Modifiez `shared/config.lua` pour adapter le script à votre serveur :
* `Config.TarpItem` : Nom de l'item requis (ex: `vehiclecoupon`).
* `Config.ConsumeItem` : Si `true`, l'item est supprimé après utilisation.
* `Config.RestrictedClasses` : Liste des classes (ID) de véhicules interdites de sauvegarde.

---

**Souhaitez-vous que je vous aide à personnaliser les couleurs du HUD ou à ajouter une fonction spécifique à la persistance ?**
