local strings = {
    SI_COVETOUSCOUNTESSASSISTANT_OPTION_TRACK_COUNTESS
        = "Suivre la Comtesse Avide",
    SI_COVETOUSCOUNTESSASSISTANT_OPTION_TRACK_COUNTESS_TOOLTIP
        = "Marquer les trésors utilisables pour les chasses de la Comtesse Avide.",
    SI_COVETOUSCOUNTESSASSISTANT_OPTION_TRACK_CROW
        = "Suivre le Trésorier des Tributs",
    SI_COVETOUSCOUNTESSASSISTANT_OPTION_TRACK_CROW_TOOLTIP
        = "Marquer les trésors utilisables pour les chasses du Trésorier des Tributs (Corbeau).",
    SI_COVETOUSCOUNTESSASSISTANT_OPTION_SETTINGS
        = "Paramètres",
    SI_COVETOUSCOUNTESSASSISTANT_MSG_COUNTESS_ON
        = "Suivi Comtesse Avide : ACTIVÉ",
    SI_COVETOUSCOUNTESSASSISTANT_MSG_COUNTESS_OFF
        = "Suivi Comtesse Avide : DÉSACTIVÉ",
    SI_COVETOUSCOUNTESSASSISTANT_MSG_CROW_ON
        = "Suivi Trésorier des Tributs : ACTIVÉ",
    SI_COVETOUSCOUNTESSASSISTANT_MSG_CROW_OFF
        = "Suivi Trésorier des Tributs : DÉSACTIVÉ",
    SI_COVETOUSCOUNTESSASSISTANT_OPTION_AUTOSKIP_TIPBOARD
        = "Ignorer offres du Tableau des indices",
    SI_COVETOUSCOUNTESSASSISTANT_OPTION_AUTOSKIP_TIPBOARD_TOOLTIP
        = "Fermer automatiquement les offres du Tableau des indices qui ne concernent pas la Comtesse Avide.",
    SI_COVETOUSCOUNTESSASSISTANT_OPTION_AUTOSKIP_TIPBOARD_WARNING
        = "Cela fermera automatiquement les dialogues autres que ceux de la Comtesse.",
}

for stringId, stringValue in pairs(strings) do
    SafeAddString(_G[stringId], stringValue, 2)
end
