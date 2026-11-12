/// TRADUCCIONES de los textos fijos de la app (botones, menús, avisos).
///
/// Formato: texto en español → [inglés, francés, alemán, portugués].
/// - La clave es EXACTAMENTE el texto que va dentro de `tr('...')`.
/// - Lo que va entre llaves ({n}, {lugar}…) se reemplaza al mostrarse y debe
///   aparecer igual en las 4 traducciones (una prueba lo revisa).
/// - Si falta una clave, la app muestra el español (no se rompe).
///
/// El CONTENIDO de la base de datos (descripciones, eventos, documentos
/// legales) no va aquí: se traduce con IA (`TraductorService`).
library;

import 'traducciones_gestion.dart';

const Map<String, List<String>> traducciones = {
  // Pantallas de comerciante y administración (archivo aparte).
  ...traduccionesGestion,

  // ----------------------------------------------------------------
  // General
  // ----------------------------------------------------------------
  'Idioma': ['Language', 'Langue', 'Sprache', 'Idioma'],
  'Explorar': ['Explore', 'Explorer', 'Entdecken', 'Explorar'],
  'Rutas': ['Routes', 'Itinéraires', 'Routen', 'Rotas'],
  'Agenda': ['Events', 'Agenda', 'Termine', 'Agenda'],
  'Pasaporte': ['Passport', 'Passeport', 'Pass', 'Passaporte'],
  'Ajustes': ['Settings', 'Paramètres', 'Einstellungen', 'Configurações'],
  'Actualizar': ['Refresh', 'Actualiser', 'Aktualisieren', 'Atualizar'],
  'Algo salió mal': ['Something went wrong', 'Un problème est survenu', 'Etwas ist schiefgelaufen', 'Algo deu errado'],
  'Reintentar': ['Try again', 'Réessayer', 'Erneut versuchen', 'Tentar de novo'],
  'Cerrar': ['Close', 'Fermer', 'Schließen', 'Fechar'],
  'Cancelar': ['Cancel', 'Annuler', 'Abbrechen', 'Cancelar'],
  'Listo': ['Done', 'Terminé', 'Fertig', 'Pronto'],
  'Entendido': ['Got it', 'Compris', 'Verstanden', 'Entendi'],
  'Enviar': ['Send', 'Envoyer', 'Senden', 'Enviar'],
  'Quitar': ['Remove', 'Retirer', 'Entfernen', 'Remover'],
  'Ver ficha': ['View details', 'Voir la fiche', 'Details ansehen', 'Ver detalhes'],
  'Ver lugar': ['View place', 'Voir le lieu', 'Ort ansehen', 'Ver lugar'],
  'Soy un negocio': ['I own a business', 'Je suis un commerce', 'Ich habe ein Geschäft', 'Tenho um negócio'],
  '¿Tienes un negocio?': ['Do you own a business?', 'Vous avez un commerce ?', 'Hast du ein Geschäft?', 'Você tem um negócio?'],
  'Pregúntale a VeraGo': ['Ask VeraGo', 'Demandez à VeraGo', 'Frag VeraGo', 'Pergunte ao VeraGo'],
  'Traducción automática con IA.': ['Automatic AI translation.', 'Traduction automatique par IA.', 'Automatische KI-Übersetzung.', 'Tradução automática com IA.'],
  'Traducción automática con IA. La versión válida es la de español.': [
    'Automatic AI translation. The Spanish version is the official one.',
    'Traduction automatique par IA. La version espagnole fait foi.',
    'Automatische KI-Übersetzung. Maßgeblich ist die spanische Fassung.',
    'Tradução automática com IA. A versão válida é a em espanhol.',
  ],
  'Revisa tu conexión a internet e intenta de nuevo.': [
    'Check your internet connection and try again.',
    'Vérifiez votre connexion Internet et réessayez.',
    'Prüfe deine Internetverbindung und versuche es erneut.',
    'Verifique sua conexão com a internet e tente de novo.',
  ],
  'Emergencia: llamar al 911': ['Emergency: call 911', 'Urgence : appeler le 911', 'Notfall: 911 anrufen', 'Emergência: ligar para 911'],
  'No pudimos abrir la app de llamadas. Marca 911 desde tu teléfono.': [
    'We couldn\'t open the phone app. Dial 911 from your phone.',
    'Impossible d\'ouvrir l\'application d\'appel. Composez le 911 depuis votre téléphone.',
    'Die Telefon-App ließ sich nicht öffnen. Wähle 911 auf deinem Telefon.',
    'Não foi possível abrir o app de chamadas. Disque 911 no seu telefone.',
  ],

  // ----------------------------------------------------------------
  // Categorías (vienen de la base de datos en español)
  // ----------------------------------------------------------------
  'Historia y monumentos': ['History & monuments', 'Histoire et monuments', 'Geschichte & Denkmäler', 'História e monumentos'],
  'Museos': ['Museums', 'Musées', 'Museen', 'Museus'],
  'Cafeterías': ['Cafés', 'Cafés', 'Cafés', 'Cafés'],
  'Restaurantes': ['Restaurants', 'Restaurants', 'Restaurants', 'Restaurantes'],
  'Tiendas y artesanías': ['Shops & crafts', 'Boutiques et artisanat', 'Läden & Kunsthandwerk', 'Lojas e artesanato'],
  'Plazas y paseos': ['Squares & promenades', 'Places et promenades', 'Plätze & Promenaden', 'Praças e passeios'],
  'Cultura': ['Culture', 'Culture', 'Kultur', 'Cultura'],
  'Puntos VeraGo': ['VeraGo Spots', 'Points VeraGo', 'VeraGo-Punkte', 'Pontos VeraGo'],

  // ----------------------------------------------------------------
  // Etiquetas
  // ----------------------------------------------------------------
  'Ficticio · demostración': ['Fictional · demo', 'Fictif · démo', 'Fiktiv · Demo', 'Fictício · demonstração'],
  'Abierto ahora': ['Open now', 'Ouvert', 'Jetzt geöffnet', 'Aberto agora'],
  'Cerrado': ['Closed', 'Fermé', 'Geschlossen', 'Fechado'],
  'Horario no disponible': ['Hours not available', 'Horaires indisponibles', 'Öffnungszeiten unbekannt', 'Horário indisponível'],
  'Negocio formal': ['Registered business', 'Commerce établi', 'Eingetragenes Geschäft', 'Negócio formal'],
  'No formal · Punto VeraGo': ['Street vendor · VeraGo Spot', 'Vendeur local · Point VeraGo', 'Straßenhändler · VeraGo-Punkt', 'Ambulante · Ponto VeraGo'],
  'Promoción': ['Special offer', 'Promotion', 'Angebot', 'Promoção'],
  'Da sello': ['Gives a stamp', 'Donne un tampon', 'Gibt Stempel', 'Dá carimbo'],
  'Da sello en tu pasaporte': ['Stamps your passport', 'Tamponne votre passeport', 'Stempel für deinen Pass', 'Carimba seu passaporte'],
  'Entrada ≈ \${n}': ['Entry ≈ \${n}', 'Entrée ≈ \${n}', 'Eintritt ≈ \${n}', 'Entrada ≈ \${n}'],
  'Oculto': ['Hidden', 'Masqué', 'Ausgeblendet', 'Oculto'],
  'Gratuito': ['Free', 'Gratuit', 'Kostenlos', 'Gratuito'],
  'Con costo': ['Paid', 'Payant', 'Kostenpflichtig', 'Pago'],
  'Cancelado': ['Cancelled', 'Annulé', 'Abgesagt', 'Cancelado'],
  'Borrador (solo admin)': ['Draft (admin only)', 'Brouillon (admin)', 'Entwurf (nur Admin)', 'Rascunho (só admin)'],
  'Alguna hora cancelada': ['Some times cancelled', 'Certains horaires annulés', 'Einige Termine abgesagt', 'Algum horário cancelado'],
  'En curso': ['Happening now', 'En cours', 'Läuft gerade', 'Acontecendo agora'],

  // ----------------------------------------------------------------
  // Bienvenida
  // ----------------------------------------------------------------
  'Saltar': ['Skip', 'Passer', 'Überspringen', 'Pular'],
  'Empezar': ['Start', 'Commencer', 'Los geht\'s', 'Começar'],
  'Siguiente': ['Next', 'Suivant', 'Weiter', 'Próximo'],
  'Descubre el Centro Histórico': ['Discover the Historic Center', 'Découvrez le centre historique', 'Entdecke die Altstadt', 'Descubra o Centro Histórico'],
  'Lugares, cafés, museos y comercios locales de Veracruz, a pocos minutos caminando.': [
    'Places, cafés, museums and local shops in Veracruz, just a few minutes\' walk away.',
    'Lieux, cafés, musées et commerces locaux de Veracruz, à quelques minutes à pied.',
    'Orte, Cafés, Museen und lokale Geschäfte in Veracruz, nur wenige Gehminuten entfernt.',
    'Lugares, cafés, museus e comércios locais de Veracruz, a poucos minutos a pé.',
  ],
  '¿Qué te interesa?': ['What are you into?', 'Qu\'est-ce qui vous intéresse ?', 'Was interessiert dich?', 'O que te interessa?'],
  'Elige lo que te gusta y armaremos rutas a tu medida.': [
    'Pick what you like and we\'ll build routes just for you.',
    'Choisissez ce qui vous plaît et nous créerons des itinéraires sur mesure.',
    'Wähle, was dir gefällt, und wir planen Routen nach deinem Geschmack.',
    'Escolha o que você gosta e montamos rotas sob medida.',
  ],
  'Mapa y lista de lugares del centro. Busca cualquier sitio de Veracruz, toca el botón de ubicación para ver dónde estás y abre la ficha de cada lugar.': [
    'Map and list of downtown places. Search any spot in Veracruz, tap the location button to see where you are, and open each place\'s details.',
    'Carte et liste des lieux du centre. Cherchez n\'importe quel endroit de Veracruz, touchez le bouton de position pour voir où vous êtes et ouvrez la fiche de chaque lieu.',
    'Karte und Liste der Orte in der Altstadt. Suche jeden Ort in Veracruz, tippe auf den Standort-Knopf, um zu sehen, wo du bist, und öffne die Details jedes Ortes.',
    'Mapa e lista de lugares do centro. Busque qualquer lugar de Veracruz, toque no botão de localização para ver onde você está e abra os detalhes de cada lugar.',
  ],
  'Dinos cuánto tiempo tienes y qué te interesa: armamos tu recorrido a pie, con el camino por las calles y la hora de llegada a cada parada.': [
    'Tell us how much time you have and what you like: we build your walking tour, with the path through the streets and the arrival time at each stop.',
    'Dites-nous combien de temps vous avez et ce qui vous intéresse : nous créons votre balade à pied, avec le chemin dans les rues et l\'heure d\'arrivée à chaque étape.',
    'Sag uns, wie viel Zeit du hast und was dich interessiert: Wir planen deinen Rundgang mit dem Weg durch die Straßen und der Ankunftszeit an jedem Halt.',
    'Diga quanto tempo você tem e o que te interessa: montamos seu passeio a pé, com o caminho pelas ruas e o horário de chegada em cada parada.',
  ],
  'Eventos de hoy y de los próximos días en el centro, con su horario y si son gratis o su costo aproximado.': [
    'Events downtown today and in the coming days, with their times and whether they are free or their approximate price.',
    'Les événements du centre aujourd\'hui et les jours suivants, avec leurs horaires et s\'ils sont gratuits ou leur prix approximatif.',
    'Veranstaltungen in der Altstadt heute und in den nächsten Tagen, mit Uhrzeit und ob sie kostenlos sind oder was sie ungefähr kosten.',
    'Eventos de hoje e dos próximos dias no centro, com horário e se são grátis ou o preço aproximado.',
  ],
  'Colecciona sellos': ['Collect stamps', 'Collectionnez les tampons', 'Sammle Stempel', 'Colecione carimbos'],
  'En Pasaporte, escanea el QR de los negocios locales y junta sellos. Con cada grupo de sellos subes de insignia, hasta "Embajador VeraGo".': [
    'In Passport, scan the QR code of local businesses and collect stamps. Each group of stamps levels up your badge, all the way to "VeraGo Ambassador".',
    'Dans Passeport, scannez le QR des commerces locaux et collectionnez les tampons. Chaque groupe de tampons améliore votre badge, jusqu\'à « Ambassadeur VeraGo ».',
    'Scanne im Pass den QR-Code lokaler Geschäfte und sammle Stempel. Mit jeder Gruppe Stempel steigt dein Abzeichen auf, bis zum „VeraGo-Botschafter“.',
    'No Passaporte, escaneie o QR dos negócios locais e junte carimbos. A cada grupo de carimbos seu emblema sobe de nível, até "Embaixador VeraGo".',
  ],
  'Tu seguridad y más': ['Your safety and more', 'Votre sécurité et plus', 'Deine Sicherheit und mehr', 'Sua segurança e mais'],
  'Pestaña {nombre} en la barra de abajo': ['{nombre} tab in the bottom bar', 'Onglet {nombre} dans la barre du bas', 'Tab {nombre} in der unteren Leiste', 'Aba {nombre} na barra de baixo'],
  'Botón 911': ['911 button', 'Bouton 911', '911-Knopf', 'Botão 911'],
  'En Explorar y en tu ruta hay un botón rojo que abre la app de llamadas con el 911.': [
    'In Explore and on your route there is a red button that opens the phone app with 911.',
    'Dans Explorer et sur votre itinéraire, un bouton rouge ouvre l\'application d\'appel avec le 911.',
    'In Entdecken und auf deiner Route gibt es einen roten Knopf, der die Telefon-App mit 911 öffnet.',
    'Em Explorar e na sua rota há um botão vermelho que abre o app de chamadas com o 911.',
  ],
  'En Pasaporte, el engrane: tu cuenta, tus intereses, esta guía, el idioma y los términos.': [
    'In Passport, the gear icon: your account, your interests, this guide, the language and the terms.',
    'Dans Passeport, l\'engrenage : votre compte, vos centres d\'intérêt, ce guide, la langue et les conditions.',
    'Im Pass das Zahnrad: dein Konto, deine Interessen, diese Anleitung, die Sprache und die Bedingungen.',
    'No Passaporte, a engrenagem: sua conta, seus interesses, este guia, o idioma e os termos.',
  ],
  'Regístralo con "Soy un negocio" (abajo) y aparece en el mapa y en las rutas.': [
    'Register it with "I own a business" (below) and it will appear on the map and in routes.',
    'Inscrivez-le avec « Je suis un commerce » (en bas) et il apparaîtra sur la carte et dans les itinéraires.',
    'Registriere es mit „Ich habe ein Geschäft“ (unten), dann erscheint es auf der Karte und in den Routen.',
    'Cadastre-o em "Tenho um negócio" (abaixo) e ele aparece no mapa e nas rotas.',
  ],

  // ----------------------------------------------------------------
  // Explorar y mapa
  // ----------------------------------------------------------------
  'Escribe al menos 3 letras para buscar en el mapa.': [
    'Type at least 3 letters to search the map.',
    'Tapez au moins 3 lettres pour chercher sur la carte.',
    'Gib mindestens 3 Buchstaben ein, um auf der Karte zu suchen.',
    'Digite pelo menos 3 letras para buscar no mapa.',
  ],
  'No encontramos "{texto}" en el mapa de Veracruz.': [
    'We couldn\'t find "{texto}" on the map of Veracruz.',
    'Nous n\'avons pas trouvé « {texto} » sur la carte de Veracruz.',
    '„{texto}“ wurde auf der Karte von Veracruz nicht gefunden.',
    'Não encontramos "{texto}" no mapa de Veracruz.',
  ],
  'Mostrando el Centro Histórico · distancias desde el Zócalo': [
    'Showing the Historic Center · distances from the Zócalo',
    'Centre historique · distances depuis le Zócalo',
    'Altstadt · Entfernungen ab dem Zócalo',
    'Mostrando o Centro Histórico · distâncias a partir do Zócalo',
  ],
  'Estás en el Centro Histórico · distancias desde donde estás': [
    'You are in the Historic Center · distances from where you are',
    'Vous êtes dans le centre historique · distances depuis votre position',
    'Du bist in der Altstadt · Entfernungen ab deinem Standort',
    'Você está no Centro Histórico · distâncias a partir de onde você está',
  ],
  'Estás a {km} km del Centro Histórico · distancias desde donde estás': [
    'You are {km} km from the Historic Center · distances from where you are',
    'Vous êtes à {km} km du centre historique · distances depuis votre position',
    'Du bist {km} km von der Altstadt entfernt · Entfernungen ab deinem Standort',
    'Você está a {km} km do Centro Histórico · distâncias a partir de onde você está',
  ],
  'Estás lejos del Centro Histórico. Seguimos midiendo las distancias desde el Zócalo.': [
    'You are far from the Historic Center. We\'ll keep measuring distances from the Zócalo.',
    'Vous êtes loin du centre historique. Les distances restent calculées depuis le Zócalo.',
    'Du bist weit von der Altstadt entfernt. Wir messen die Entfernungen weiter ab dem Zócalo.',
    'Você está longe do Centro Histórico. Continuamos medindo as distâncias a partir do Zócalo.',
  ],
  'Aún no hay lugares': ['No places yet', 'Aucun lieu pour l\'instant', 'Noch keine Orte', 'Ainda não há lugares'],
  'Cuando se carguen lugares en la base de datos, aparecerán aquí.': [
    'Places will appear here once they are added to the database.',
    'Les lieux apparaîtront ici dès qu\'ils seront ajoutés.',
    'Sobald Orte hinzugefügt werden, erscheinen sie hier.',
    'Quando os lugares forem cadastrados, aparecerão aqui.',
  ],
  'Busca un lugar, café, museo…': ['Search for a place, café, museum…', 'Cherchez un lieu, café, musée…', 'Suche einen Ort, ein Café, ein Museum…', 'Busque um lugar, café, museu…'],
  'Borrar búsqueda': ['Clear search', 'Effacer la recherche', 'Suche löschen', 'Limpar busca'],
  'Buscar "{texto}" en todo el mapa': ['Search "{texto}" on the whole map', 'Chercher « {texto} » sur toute la carte', '„{texto}“ auf der ganzen Karte suchen', 'Buscar "{texto}" no mapa todo'],
  '{n} en el mapa de OpenStreetMap': ['{n} on the OpenStreetMap map', '{n} sur la carte OpenStreetMap', '{n} auf der OpenStreetMap-Karte', '{n} no mapa do OpenStreetMap'],
  'Todos': ['All', 'Tous', 'Alle', 'Todos'],
  'Mapa': ['Map', 'Carte', 'Karte', 'Mapa'],
  'Lista': ['List', 'Liste', 'Liste', 'Lista'],
  'Sin resultados en VeraGo': ['No results in VeraGo', 'Aucun résultat dans VeraGo', 'Keine Treffer in VeraGo', 'Sem resultados no VeraGo'],
  'Puedes buscarlo en todo el mapa de Veracruz.': [
    'You can search for it on the whole map of Veracruz.',
    'Vous pouvez le chercher sur toute la carte de Veracruz.',
    'Du kannst es auf der ganzen Karte von Veracruz suchen.',
    'Você pode buscar no mapa todo de Veracruz.',
  ],
  'Prueba con otra palabra o quita el filtro.': ['Try another word or remove the filter.', 'Essayez un autre mot ou retirez le filtre.', 'Versuche ein anderes Wort oder entferne den Filter.', 'Tente outra palavra ou tire o filtro.'],
  'Buscar en el mapa': ['Search the map', 'Chercher sur la carte', 'Auf der Karte suchen', 'Buscar no mapa'],
  'En el mapa (OpenStreetMap, no son parte de VeraGo)': [
    'On the map (OpenStreetMap, not part of VeraGo)',
    'Sur la carte (OpenStreetMap, hors VeraGo)',
    'Auf der Karte (OpenStreetMap, nicht Teil von VeraGo)',
    'No mapa (OpenStreetMap, não fazem parte do VeraGo)',
  ],
  'Lugar de OpenStreetMap: no es parte de VeraGo.': [
    'OpenStreetMap place: not part of VeraGo.',
    'Lieu OpenStreetMap : ne fait pas partie de VeraGo.',
    'OpenStreetMap-Ort: nicht Teil von VeraGo.',
    'Lugar do OpenStreetMap: não faz parte do VeraGo.',
  ],
  '{lugar} (lugar del mapa)': ['{lugar} (map place)', '{lugar} (lieu de la carte)', '{lugar} (Ort auf der Karte)', '{lugar} (lugar do mapa)'],
  'Mostrar dónde estoy': ['Show where I am', 'Afficher ma position', 'Meinen Standort zeigen', 'Mostrar onde estou'],
  'Volver a centrar el mapa': ['Re-center the map', 'Recentrer la carte', 'Karte zentrieren', 'Centralizar o mapa'],
  'Ocultar leyenda': ['Hide legend', 'Masquer la légende', 'Legende ausblenden', 'Ocultar legenda'],
  'Ver leyenda de colores': ['Show color legend', 'Voir la légende des couleurs', 'Farblegende anzeigen', 'Ver legenda de cores'],
  'Estás aquí': ['You are here', 'Vous êtes ici', 'Du bist hier', 'Você está aqui'],

  // ----------------------------------------------------------------
  // Ficha del lugar
  // ----------------------------------------------------------------
  '{categoria} · {distancia} del Zócalo': ['{categoria} · {distancia} from the Zócalo', '{categoria} · à {distancia} du Zócalo', '{categoria} · {distancia} vom Zócalo', '{categoria} · {distancia} do Zócalo'],
  'Visita sugerida: {min} min': ['Suggested visit: {min} min', 'Visite conseillée : {min} min', 'Empfohlene Besuchszeit: {min} Min.', 'Visita sugerida: {min} min'],
  'Costo de entrada no disponible: confírmalo en el lugar.': [
    'Entry price not available: check on site.',
    'Prix d\'entrée non disponible : vérifiez sur place.',
    'Eintrittspreis unbekannt: bitte vor Ort nachfragen.',
    'Preço de entrada indisponível: confirme no local.',
  ],
  'Entrada gratis': ['Free entry', 'Entrée gratuite', 'Eintritt frei', 'Entrada grátis'],
  'Entrada aprox. \${c} MXN': ['Entry approx. \${c} MXN', 'Entrée env. \${c} MXN', 'Eintritt ca. \${c} MXN', 'Entrada aprox. \${c} MXN'],
  'Vitrina': ['Showcase', 'Vitrine', 'Schaufenster', 'Vitrine'],
  'Precios aproximados que da el negocio.': [
    'Approximate prices provided by the business.',
    'Prix approximatifs indiqués par le commerce.',
    'Ungefähre Preise laut Geschäft.',
    'Preços aproximados informados pelo negócio.',
  ],
  '{giro} · Lo encuentras en {punto}, en el horario del punto.': [
    '{giro} · Find it at {punto}, during the spot\'s opening hours.',
    '{giro} · Vous le trouverez à {punto}, aux horaires du point.',
    '{giro} · Zu finden bei {punto}, zu den Öffnungszeiten des Punkts.',
    '{giro} · Você encontra em {punto}, no horário do ponto.',
  ],
  'Emprendedor local': ['Local entrepreneur', 'Entrepreneur local', 'Lokaler Kleinunternehmer', 'Empreendedor local'],
  'Punto VeraGo: mesas de emprendedores locales en un lugar especial del centro, con un negocio de cada giro.': [
    'VeraGo Spot: stalls of local entrepreneurs in a special downtown place, with one business of each kind.',
    'Point VeraGo : stands d\'entrepreneurs locaux dans un lieu spécial du centre, avec un commerce de chaque type.',
    'VeraGo-Punkt: Stände lokaler Kleinunternehmer an einem besonderen Ort der Altstadt, je ein Geschäft pro Branche.',
    'Ponto VeraGo: bancas de empreendedores locais num lugar especial do centro, com um negócio de cada ramo.',
  ],
  'Pide en el comercio su código QR y escanéalo desde la pestaña Pasaporte para ganar su sello.': [
    'Ask the shop for its QR code and scan it from the Passport tab to earn its stamp.',
    'Demandez le QR au commerce et scannez-le depuis l\'onglet Passeport pour gagner son tampon.',
    'Frag im Geschäft nach dem QR-Code und scanne ihn im Tab Pass, um den Stempel zu bekommen.',
    'Peça o QR no comércio e escaneie na aba Passaporte para ganhar o carimbo.',
  ],
  'Horario': ['Opening hours', 'Horaires', 'Öffnungszeiten', 'Horário'],
  'Horario no disponible. Consulta directamente en el lugar.': [
    'Hours not available. Please check on site.',
    'Horaires indisponibles. Renseignez-vous sur place.',
    'Öffnungszeiten unbekannt. Bitte vor Ort nachfragen.',
    'Horário indisponível. Consulte diretamente no local.',
  ],
  'Horario ficticio de demostración.': ['Fictional demo hours.', 'Horaires fictifs de démonstration.', 'Fiktive Demo-Öffnungszeiten.', 'Horário fictício de demonstração.'],
  'Contacto': ['Contact', 'Contact', 'Kontakt', 'Contato'],
  'Ubicación': ['Location', 'Emplacement', 'Lage', 'Localização'],
  'Ubicación aproximada.': ['Approximate location.', 'Emplacement approximatif.', 'Ungefähre Lage.', 'Localização aproximada.'],
  'Reportar un problema': ['Report a problem', 'Signaler un problème', 'Problem melden', 'Relatar um problema'],
  'Comerciantes en este punto': ['Vendors at this spot', 'Commerçants de ce point', 'Händler an diesem Punkt', 'Comerciantes neste ponto'],
  'Cerca de aquí': ['Nearby', 'À proximité', 'In der Nähe', 'Perto daqui'],
  'Comercios locales a menos de {min} minutos caminando.': [
    'Local shops less than {min} minutes\' walk away.',
    'Commerces locaux à moins de {min} minutes à pied.',
    'Lokale Geschäfte weniger als {min} Gehminuten entfernt.',
    'Comércios locais a menos de {min} minutos a pé.',
  ],
  '{dia} (hoy)': ['{dia} (today)', '{dia} (aujourd\'hui)', '{dia} (heute)', '{dia} (hoje)'],

  // ----------------------------------------------------------------
  // Reportar un problema
  // ----------------------------------------------------------------
  '¿Qué pasa con {lugar}?': ['What\'s wrong with {lugar}?', 'Quel est le problème avec {lugar} ?', 'Was stimmt nicht mit {lugar}?', 'O que há de errado com {lugar}?'],
  'La ubicación está mal': ['The location is wrong', 'L\'emplacement est faux', 'Die Lage ist falsch', 'A localização está errada'],
  'El horario está mal o está cerrado': ['The hours are wrong or it is closed', 'Les horaires sont faux ou c\'est fermé', 'Die Öffnungszeiten stimmen nicht oder es ist geschlossen', 'O horário está errado ou está fechado'],
  'La información es falsa o engañosa': ['The information is false or misleading', 'L\'information est fausse ou trompeuse', 'Die Angaben sind falsch oder irreführend', 'A informação é falsa ou enganosa'],
  'La foto no corresponde o es inapropiada': ['The photo is wrong or inappropriate', 'La photo ne correspond pas ou est inappropriée', 'Das Foto passt nicht oder ist unangemessen', 'A foto não corresponde ou é imprópria'],
  'El QR no funciona': ['The QR code doesn\'t work', 'Le QR ne fonctionne pas', 'Der QR-Code funktioniert nicht', 'O QR não funciona'],
  'Otro': ['Other', 'Autre', 'Sonstiges', 'Outro'],
  'Copia el reporte y envíalo al equipo de VeraGo.': [
    'Copy the report and send it to the VeraGo team.',
    'Copiez le signalement et envoyez-le à l\'équipe VeraGo.',
    'Kopiere die Meldung und schicke sie an das VeraGo-Team.',
    'Copie o relato e envie para a equipe do VeraGo.',
  ],
  'Copia el reporte y envíalo a {correo}.': [
    'Copy the report and send it to {correo}.',
    'Copiez le signalement et envoyez-le à {correo}.',
    'Kopiere die Meldung und schicke sie an {correo}.',
    'Copie o relato e envie para {correo}.',
  ],
  'No guardamos tu reporte en la app.': ['We don\'t store your report in the app.', 'Votre signalement n\'est pas enregistré dans l\'app.', 'Deine Meldung wird nicht in der App gespeichert.', 'Não guardamos seu relato no app.'],
  'Copiar reporte': ['Copy report', 'Copier le signalement', 'Meldung kopieren', 'Copiar relato'],
  'Reporte copiado. Pégalo en un correo al equipo de VeraGo.': [
    'Report copied. Paste it into an email to the VeraGo team.',
    'Signalement copié. Collez-le dans un e-mail à l\'équipe VeraGo.',
    'Meldung kopiert. Füge sie in eine E-Mail an das VeraGo-Team ein.',
    'Relato copiado. Cole num e-mail para a equipe do VeraGo.',
  ],

  // ----------------------------------------------------------------
  // Rutas
  // ----------------------------------------------------------------
  'Tranquilo': ['Relaxed', 'Tranquille', 'Gemütlich', 'Tranquilo'],
  'Normal': ['Normal', 'Normal', 'Normal', 'Normal'],
  'Rápido': ['Fast', 'Rapide', 'Zügig', 'Rápido'],
  'el Zócalo': ['the Zócalo', 'le Zócalo', 'dem Zócalo', 'o Zócalo'],
  'tu ubicación': ['your location', 'votre position', 'deinem Standort', 'sua localização'],
  'Estás lejos del Centro Histórico. Armamos tu ruta desde el Zócalo.': [
    'You are far from the Historic Center. We built your route from the Zócalo.',
    'Vous êtes loin du centre historique. Votre itinéraire part du Zócalo.',
    'Du bist weit von der Altstadt entfernt. Deine Route startet am Zócalo.',
    'Você está longe do Centro Histórico. Montamos sua rota a partir do Zócalo.',
  ],
  'Tu recorrido a la medida': ['Your tailor-made tour', 'Votre balade sur mesure', 'Dein Rundgang nach Maß', 'Seu passeio sob medida'],
  'Dinos cuánto tiempo tienes y qué te gusta.': ['Tell us how much time you have and what you like.', 'Dites-nous combien de temps vous avez et ce qui vous plaît.', 'Sag uns, wie viel Zeit du hast und was dir gefällt.', 'Diga quanto tempo você tem e do que gosta.'],
  '¿Cuánto tiempo tienes?': ['How much time do you have?', 'Combien de temps avez-vous ?', 'Wie viel Zeit hast du?', 'Quanto tempo você tem?'],
  'Elige al menos uno para generar tu ruta.': ['Pick at least one to build your route.', 'Choisissez-en au moins un pour créer votre itinéraire.', 'Wähle mindestens eins, um deine Route zu erstellen.', 'Escolha pelo menos um para gerar sua rota.'],
  'Tu ruta solo tendrá lugares de lo que elijas.': ['Your route will only include what you pick.', 'Votre itinéraire ne comprendra que vos choix.', 'Deine Route enthält nur, was du auswählst.', 'Sua rota só terá lugares do que você escolher.'],
  'Tu ritmo al caminar': ['Your walking pace', 'Votre rythme de marche', 'Dein Gehtempo', 'Seu ritmo de caminhada'],
  '¿Desde dónde empiezas?': ['Where do you start?', 'D\'où partez-vous ?', 'Wo startest du?', 'De onde você começa?'],
  'Zócalo': ['Zócalo', 'Zócalo', 'Zócalo', 'Zócalo'],
  'Mi ubicación': ['My location', 'Ma position', 'Mein Standort', 'Minha localização'],
  'Usamos tu ubicación solo para empezar la ruta. No la guardamos.': [
    'We only use your location to start the route. We don\'t store it.',
    'Votre position sert seulement à démarrer l\'itinéraire. Elle n\'est pas enregistrée.',
    'Dein Standort wird nur für den Start der Route genutzt und nicht gespeichert.',
    'Usamos sua localização só para iniciar a rota. Não a guardamos.',
  ],
  'Generar ruta': ['Build route', 'Créer l\'itinéraire', 'Route erstellen', 'Gerar rota'],
  'Entre historia y sabores': ['History and flavors', 'Histoire et saveurs', 'Geschichte und Genuss', 'Entre história e sabores'],
  'Recorrido histórico': ['Historic tour', 'Balade historique', 'Historischer Rundgang', 'Passeio histórico'],
  'Ruta de sabores': ['Flavor route', 'Route des saveurs', 'Genussroute', 'Rota de sabores'],
  'Tu recorrido por el centro': ['Your downtown tour', 'Votre balade dans le centre', 'Dein Altstadt-Rundgang', 'Seu passeio pelo centro'],
  'No encontramos una ruta': ['We couldn\'t find a route', 'Aucun itinéraire trouvé', 'Keine Route gefunden', 'Não encontramos uma rota'],
  'Con ese tiempo, horario o intereses no alcanzamos a incluir lugares abiertos. Prueba con más tiempo o elige más intereses.': [
    'With that time, schedule or interests we couldn\'t fit any open places. Try more time or pick more interests.',
    'Avec ce temps, cet horaire ou ces intérêts, aucun lieu ouvert ne rentre. Essayez avec plus de temps ou plus d\'intérêts.',
    'Mit dieser Zeit, Uhrzeit oder diesen Interessen passen keine geöffneten Orte. Versuche mehr Zeit oder mehr Interessen.',
    'Com esse tempo, horário ou interesses não coube nenhum lugar aberto. Tente mais tempo ou escolha mais interesses.',
  ],
  'Cambiar preferencias': ['Change preferences', 'Modifier les préférences', 'Einstellungen ändern', 'Mudar preferências'],
  'Trazando el camino por las calles…': ['Drawing the path through the streets…', 'Tracé du chemin dans les rues…', 'Weg durch die Straßen wird berechnet…', 'Traçando o caminho pelas ruas…'],
  'Camino a pie por las calles (OpenStreetMap). Es aproximado: sigue las señales y cruza con cuidado.': [
    'Walking path through the streets (OpenStreetMap). It is approximate: follow the signs and cross carefully.',
    'Chemin à pied dans les rues (OpenStreetMap). Il est approximatif : suivez les panneaux et traversez prudemment.',
    'Fußweg durch die Straßen (OpenStreetMap). Er ist ungefähr: Achte auf Schilder und überquere vorsichtig.',
    'Caminho a pé pelas ruas (OpenStreetMap). É aproximado: siga as placas e atravesse com cuidado.',
  ],
  'Sin conexión para trazar las calles: la línea es recta y aproximada.': [
    'No connection to draw the streets: the line is straight and approximate.',
    'Pas de connexion pour tracer les rues : la ligne est droite et approximative.',
    'Keine Verbindung für den Straßenweg: Die Linie ist gerade und ungefähr.',
    'Sem conexão para traçar as ruas: a linha é reta e aproximada.',
  ],
  '{n} paradas · {min} min caminando · termina a las {hora}': [
    '{n} stops · {min} min walking · ends at {hora}',
    '{n} étapes · {min} min de marche · fin à {hora}',
    '{n} Halte · {min} Min. zu Fuß · Ende um {hora}',
    '{n} paradas · {min} min a pé · termina às {hora}',
  ],
  'Algunos lugares no tienen horario cargado: confirma en el lugar antes de ir. Los tiempos de caminata son aproximados.': [
    'Some places have no hours listed: check before you go. Walking times are approximate.',
    'Certains lieux n\'ont pas d\'horaires : vérifiez avant d\'y aller. Les temps de marche sont approximatifs.',
    'Für manche Orte fehlen Öffnungszeiten: Prüfe sie vorher. Die Gehzeiten sind ungefähr.',
    'Alguns lugares não têm horário cadastrado: confirme antes de ir. Os tempos de caminhada são aproximados.',
  ],
  '{min} min caminando · visita sugerida {visita} min': [
    '{min} min walking · suggested visit {visita} min',
    '{min} min de marche · visite conseillée {visita} min',
    '{min} Min. zu Fuß · empfohlener Besuch {visita} Min.',
    '{min} min a pé · visita sugerida {visita} min',
  ],
  'Te quedan {min} min libres': ['You have {min} min left', 'Il vous reste {min} min', 'Du hast noch {min} Min. frei', 'Restam {min} min livres'],
  'A {min} min de tu última parada está {lugar}. ¿Por qué no vas?': [
    '{lugar} is {min} min from your last stop. Why not go?',
    '{lugar} est à {min} min de votre dernière étape. Pourquoi ne pas y aller ?',
    '{lugar} ist {min} Min. von deinem letzten Halt entfernt. Wie wär\'s?',
    'A {min} min da sua última parada fica {lugar}. Que tal ir?',
  ],
  'Punto VeraGo: 1 emprendedor local': ['VeraGo Spot: 1 local entrepreneur', 'Point VeraGo : 1 entrepreneur local', 'VeraGo-Punkt: 1 lokaler Kleinunternehmer', 'Ponto VeraGo: 1 empreendedor local'],
  'Punto VeraGo: {n} emprendedores locales': ['VeraGo Spot: {n} local entrepreneurs', 'Point VeraGo : {n} entrepreneurs locaux', 'VeraGo-Punkt: {n} lokale Kleinunternehmer', 'Ponto VeraGo: {n} empreendedores locais'],
  'Te interesa: {categoria}': ['You like: {categoria}', 'Vous aimez : {categoria}', 'Dich interessiert: {categoria}', 'Você curte: {categoria}'],
  'Imperdible del centro': ['Downtown must-see', 'Incontournable du centre', 'Ein Muss in der Altstadt', 'Imperdível do centro'],
  'Comercio local': ['Local business', 'Commerce local', 'Lokales Geschäft', 'Comércio local'],
  'A {min} min de {inicio}': ['{min} min from {inicio}', 'À {min} min de {inicio}', '{min} Min. von {inicio}', 'A {min} min de {inicio}'],
  'A {min} min de la parada anterior': ['{min} min from the previous stop', 'À {min} min de l\'étape précédente', '{min} Min. vom vorherigen Halt', 'A {min} min da parada anterior'],

  // ----------------------------------------------------------------
  // Agenda
  // ----------------------------------------------------------------
  'Hoy ({n})': ['Today ({n})', 'Aujourd\'hui ({n})', 'Heute ({n})', 'Hoje ({n})'],
  'Próximos ({n})': ['Upcoming ({n})', 'À venir ({n})', 'Demnächst ({n})', 'Próximos ({n})'],
  'Más lejano primero': ['Latest first', 'Plus lointain d\'abord', 'Späteste zuerst', 'Mais distante primeiro'],
  'Más pronto primero': ['Soonest first', 'Plus proche d\'abord', 'Früheste zuerst', 'Mais próximo primeiro'],
  'No hay eventos hoy': ['No events today', 'Aucun événement aujourd\'hui', 'Heute keine Veranstaltungen', 'Não há eventos hoje'],
  'No hay eventos próximos': ['No upcoming events', 'Aucun événement à venir', 'Keine kommenden Veranstaltungen', 'Não há próximos eventos'],
  'Revisa los próximos días.': ['Check the coming days.', 'Regardez les prochains jours.', 'Schau dir die nächsten Tage an.', 'Veja os próximos dias.'],
  'Vuelve pronto: aquí aparecerán nuevos eventos.': ['Come back soon: new events will show up here.', 'Revenez bientôt : de nouveaux événements apparaîtront ici.', 'Schau bald wieder vorbei: Hier erscheinen neue Veranstaltungen.', 'Volte logo: novos eventos aparecerão aqui.'],
  'Ver próximos': ['See upcoming', 'Voir à venir', 'Demnächst ansehen', 'Ver próximos'],
  'Costo: {costo}': ['Price: {costo}', 'Prix : {costo}', 'Preis: {costo}', 'Preço: {costo}'],
  ' (ficticio)': [' (fictional)', ' (fictif)', ' (fiktiv)', ' (fictício)'],
  '{n} horarios': ['{n} times', '{n} horaires', '{n} Termine', '{n} horários'],
  'Cada {tiempo}': ['Every {tiempo}', 'Toutes les {tiempo}', 'Alle {tiempo}', 'A cada {tiempo}'],
  '{desde} a {hasta}': ['{desde} to {hasta}', '{desde} à {hasta}', '{desde} bis {hasta}', '{desde} às {hasta}'],
  'No pudimos cargar la agenda. Intenta de nuevo.': ['We couldn\'t load the events. Try again.', 'Impossible de charger l\'agenda. Réessayez.', 'Termine konnten nicht geladen werden. Versuche es erneut.', 'Não foi possível carregar a agenda. Tente de novo.'],

  // ----------------------------------------------------------------
  // Pasaporte e insignias
  // ----------------------------------------------------------------
  'Tu pasaporte VeraGo': ['Your VeraGo passport', 'Votre passeport VeraGo', 'Dein VeraGo-Pass', 'Seu passaporte VeraGo'],
  'Escanea el QR de los comercios participantes y colecciona sus sellos. Necesitas una cuenta para guardarlos.': [
    'Scan the QR code of participating shops and collect their stamps. You need an account to save them.',
    'Scannez le QR des commerces participants et collectionnez leurs tampons. Un compte est nécessaire pour les garder.',
    'Scanne den QR-Code teilnehmender Geschäfte und sammle Stempel. Zum Speichern brauchst du ein Konto.',
    'Escaneie o QR dos comércios participantes e colecione os carimbos. Você precisa de uma conta para guardá-los.',
  ],
  'Iniciar sesión': ['Sign in', 'Se connecter', 'Anmelden', 'Entrar'],
  'Hola, {nombre}': ['Hi, {nombre}', 'Bonjour, {nombre}', 'Hallo, {nombre}', 'Olá, {nombre}'],
  '{n} de {total}': ['{n} of {total}', '{n} sur {total}', '{n} von {total}', '{n} de {total}'],
  'comercios sellados en tu pasaporte': ['shops stamped in your passport', 'commerces tamponnés dans votre passeport', 'Geschäfte in deinem Pass gestempelt', 'comércios carimbados no seu passaporte'],
  'Escanear QR': ['Scan QR', 'Scanner le QR', 'QR scannen', 'Escanear QR'],
  'Tu colección': ['Your collection', 'Votre collection', 'Deine Sammlung', 'Sua coleção'],
  'Historial': ['History', 'Historique', 'Verlauf', 'Histórico'],
  'Aún no tienes sellos. Visita un comercio participante y escanea su QR.': [
    'No stamps yet. Visit a participating shop and scan its QR code.',
    'Pas encore de tampons. Visitez un commerce participant et scannez son QR.',
    'Noch keine Stempel. Besuche ein teilnehmendes Geschäft und scanne seinen QR-Code.',
    'Você ainda não tem carimbos. Visite um comércio participante e escaneie o QR.',
  ],
  'Sin insignia todavía': ['No badge yet', 'Pas encore de badge', 'Noch kein Abzeichen', 'Ainda sem emblema'],
  'Consigue sellos para ganar tu primera insignia.': ['Collect stamps to earn your first badge.', 'Collectionnez des tampons pour gagner votre premier badge.', 'Sammle Stempel für dein erstes Abzeichen.', 'Junte carimbos para ganhar seu primeiro emblema.'],
  'Te falta 1 sello para "{nivel}"': ['1 more stamp to "{nivel}"', 'Encore 1 tampon pour « {nivel} »', 'Noch 1 Stempel bis „{nivel}“', 'Falta 1 carimbo para "{nivel}"'],
  'Te faltan {n} sellos para "{nivel}"': ['{n} more stamps to "{nivel}"', 'Encore {n} tampons pour « {nivel} »', 'Noch {n} Stempel bis „{nivel}“', 'Faltam {n} carimbos para "{nivel}"'],
  '¡Tienes todas las insignias!': ['You have every badge!', 'Vous avez tous les badges !', 'Du hast alle Abzeichen!', 'Você tem todos os emblemas!'],
  '{nivel}: {n} sellos': ['{nivel}: {n} stamps', '{nivel} : {n} tampons', '{nivel}: {n} Stempel', '{nivel}: {n} carimbos'],
  'sello obtenido': ['stamp earned', 'tampon obtenu', 'Stempel erhalten', 'carimbo obtido'],
  'sello pendiente': ['stamp pending', 'tampon à obtenir', 'Stempel fehlt', 'carimbo pendente'],
  'Visitante': ['Visitor', 'Visiteur', 'Besucher', 'Visitante'],
  'Explorador': ['Explorer', 'Explorateur', 'Entdecker', 'Explorador'],
  'Viajero': ['Traveler', 'Voyageur', 'Reisender', 'Viajante'],
  'Jarocho': ['Jarocho', 'Jarocho', 'Jarocho', 'Jarocho'],
  'Embajador VeraGo': ['VeraGo Ambassador', 'Ambassadeur VeraGo', 'VeraGo-Botschafter', 'Embaixador VeraGo'],
  'Diste tus primeros pasos por el centro.': ['You took your first steps downtown.', 'Vos premiers pas dans le centre.', 'Deine ersten Schritte in der Altstadt.', 'Você deu seus primeiros passos pelo centro.'],
  'Ya conoces varios rincones del puerto.': ['You already know several corners of the port.', 'Vous connaissez déjà plusieurs coins du port.', 'Du kennst schon einige Ecken der Hafenstadt.', 'Você já conhece vários cantos do porto.'],
  'Recorriste la mitad de los negocios.': ['You visited half of the businesses.', 'Vous avez visité la moitié des commerces.', 'Du hast die Hälfte der Geschäfte besucht.', 'Você visitou metade dos negócios.'],
  'Conoces el centro como alguien de aquí.': ['You know downtown like a local (a "jarocho").', 'Vous connaissez le centre comme un local (un « jarocho »).', 'Du kennst die Altstadt wie ein Einheimischer („Jarocho“).', 'Você conhece o centro como alguém daqui (um "jarocho").'],
  '¡Visitaste todos los negocios! El centro es tuyo.': ['You visited every business! Downtown is yours.', 'Vous avez visité tous les commerces ! Le centre est à vous.', 'Du hast alle Geschäfte besucht! Die Altstadt gehört dir.', 'Você visitou todos os negócios! O centro é seu.'],

  // ----------------------------------------------------------------
  // Escanear
  // ----------------------------------------------------------------
  '¡Nuevo sello!': ['New stamp!', 'Nouveau tampon !', 'Neuer Stempel!', 'Novo carimbo!'],
  'No se registró el sello': ['The stamp was not saved', 'Le tampon n\'a pas été enregistré', 'Der Stempel wurde nicht gespeichert', 'O carimbo não foi registrado'],
  'A {min} min de aquí está {lugar}. ¿Por qué no vas?': [
    '{lugar} is {min} min from here. Why not go?',
    '{lugar} est à {min} min d\'ici. Pourquoi ne pas y aller ?',
    '{lugar} ist {min} Min. von hier entfernt. Wie wär\'s?',
    'A {min} min daqui fica {lugar}. Que tal ir?',
  ],
  'Apunta la cámara al código QR que te muestra el comercio.': [
    'Point the camera at the QR code the shop shows you.',
    'Pointez la caméra vers le QR que vous montre le commerce.',
    'Richte die Kamera auf den QR-Code, den dir das Geschäft zeigt.',
    'Aponte a câmera para o QR que o comércio mostra.',
  ],
  'No pudimos usar la cámara. Revisa el permiso o escribe el código abajo.': [
    'We couldn\'t use the camera. Check the permission or type the code below.',
    'Impossible d\'utiliser la caméra. Vérifiez l\'autorisation ou saisissez le code ci-dessous.',
    'Die Kamera ließ sich nicht nutzen. Prüfe die Berechtigung oder gib den Code unten ein.',
    'Não foi possível usar a câmera. Verifique a permissão ou digite o código abaixo.',
  ],
  '¿No funciona la cámara? Escribe el código:': ['Camera not working? Type the code:', 'La caméra ne marche pas ? Saisissez le code :', 'Kamera geht nicht? Gib den Code ein:', 'A câmera não funciona? Digite o código:'],
  'Validar código': ['Check code', 'Valider le code', 'Code prüfen', 'Validar código'],
  'El código empieza con VG- y tiene 32 letras y números': [
    'The code starts with VG- and has 32 letters and numbers',
    'Le code commence par VG- et contient 32 lettres et chiffres',
    'Der Code beginnt mit VG- und hat 32 Buchstaben und Ziffern',
    'O código começa com VG- e tem 32 letras e números',
  ],
  'Sin conexión: el sello necesita internet para validarse en el momento (el QR cambia cada 60 segundos). Vuelve a escanear cuando tengas señal.': [
    'No connection: the stamp needs internet to be checked right away (the QR changes every 60 seconds). Scan again when you have signal.',
    'Pas de connexion : le tampon doit être validé en ligne immédiatement (le QR change toutes les 60 secondes). Scannez à nouveau quand vous aurez du réseau.',
    'Keine Verbindung: Der Stempel muss sofort online geprüft werden (der QR-Code ändert sich alle 60 Sekunden). Scanne erneut, wenn du Empfang hast.',
    'Sem conexão: o carimbo precisa de internet para ser validado na hora (o QR muda a cada 60 segundos). Escaneie de novo quando tiver sinal.',
  ],
  '¡Sello obtenido en {lugar}! Llevas {n} en tu pasaporte.': [
    'Stamp earned at {lugar}! You have {n} in your passport.',
    'Tampon obtenu chez {lugar} ! Vous en avez {n} dans votre passeport.',
    'Stempel bei {lugar} erhalten! Du hast {n} in deinem Pass.',
    'Carimbo obtido em {lugar}! Você tem {n} no seu passaporte.',
  ],
  'Ya tienes el sello de {lugar} de hoy. Vuelve otro día o descubre otro lugar.': [
    'You already have today\'s stamp from {lugar}. Come back another day or discover another place.',
    'Vous avez déjà le tampon de {lugar} aujourd\'hui. Revenez un autre jour ou découvrez un autre lieu.',
    'Du hast den Stempel von {lugar} heute schon. Komm an einem anderen Tag wieder oder entdecke einen anderen Ort.',
    'Você já tem o carimbo de {lugar} de hoje. Volte outro dia ou descubra outro lugar.',
  ],
  'Inicia sesión para guardar tus sellos.': ['Sign in to save your stamps.', 'Connectez-vous pour garder vos tampons.', 'Melde dich an, um deine Stempel zu speichern.', 'Entre para guardar seus carimbos.'],
  'No puedes darte un sello de tu propio negocio. Pide a un turista que lo escanee.': [
    'You can\'t stamp your own business. Ask a visitor to scan it.',
    'Vous ne pouvez pas tamponner votre propre commerce. Demandez à un visiteur de le scanner.',
    'Du kannst dein eigenes Geschäft nicht stempeln. Bitte einen Besucher, es zu scannen.',
    'Você não pode se dar um carimbo do seu próprio negócio. Peça a um turista para escanear.',
  ],
  'Este código ya venció o no es válido. Pide al comercio que te muestre el QR actual.': [
    'This code has expired or is not valid. Ask the shop to show you the current QR code.',
    'Ce code a expiré ou n\'est pas valide. Demandez au commerce de vous montrer le QR actuel.',
    'Dieser Code ist abgelaufen oder ungültig. Bitte das Geschäft um den aktuellen QR-Code.',
    'Este código venceu ou não é válido. Peça ao comércio para mostrar o QR atual.',
  ],
  'No pudimos validar el código. Intenta de nuevo.': ['We couldn\'t check the code. Try again.', 'Impossible de valider le code. Réessayez.', 'Der Code konnte nicht geprüft werden. Versuche es erneut.', 'Não foi possível validar o código. Tente de novo.'],
  'No pudimos cargar tus sellos. Intenta de nuevo.': ['We couldn\'t load your stamps. Try again.', 'Impossible de charger vos tampons. Réessayez.', 'Deine Stempel konnten nicht geladen werden. Versuche es erneut.', 'Não foi possível carregar seus carimbos. Tente de novo.'],
  'No pudimos cargar tu perfil. Intenta de nuevo.': ['We couldn\'t load your profile. Try again.', 'Impossible de charger votre profil. Réessayez.', 'Dein Profil konnte nicht geladen werden. Versuche es erneut.', 'Não foi possível carregar seu perfil. Tente de novo.'],
  'No pudimos cargar los lugares. Intenta de nuevo.': ['We couldn\'t load the places. Try again.', 'Impossible de charger les lieux. Réessayez.', 'Die Orte konnten nicht geladen werden. Versuche es erneut.', 'Não foi possível carregar os lugares. Tente de novo.'],
  'No pudimos cargar tu comercio. Intenta de nuevo.': ['We couldn\'t load your business. Try again.', 'Impossible de charger votre commerce. Réessayez.', 'Dein Geschäft konnte nicht geladen werden. Versuche es erneut.', 'Não foi possível carregar seu comércio. Tente de novo.'],
  'No pudimos generar el código. Revisa tu conexión.': ['We couldn\'t create the code. Check your connection.', 'Impossible de générer le code. Vérifiez votre connexion.', 'Der Code konnte nicht erstellt werden. Prüfe deine Verbindung.', 'Não foi possível gerar o código. Verifique sua conexão.'],
  'Tu cuenta no está autorizada para mostrar el QR de este comercio.': [
    'Your account is not allowed to show this shop\'s QR code.',
    'Votre compte n\'est pas autorisé à afficher le QR de ce commerce.',
    'Dein Konto darf den QR-Code dieses Geschäfts nicht anzeigen.',
    'Sua conta não tem permissão para mostrar o QR deste comércio.',
  ],

  // ----------------------------------------------------------------
  // Ubicación
  // ----------------------------------------------------------------
  'Activa la ubicación (GPS) de tu celular.': ['Turn on your phone\'s location (GPS).', 'Activez la localisation (GPS) de votre téléphone.', 'Schalte den Standort (GPS) deines Handys ein.', 'Ative a localização (GPS) do seu celular.'],
  'Sin permiso de ubicación. Puedes iniciar desde el Zócalo.': ['No location permission. You can start from the Zócalo.', 'Pas d\'autorisation de localisation. Vous pouvez partir du Zócalo.', 'Keine Standortberechtigung. Du kannst am Zócalo starten.', 'Sem permissão de localização. Você pode começar pelo Zócalo.'],
  'No pudimos obtener tu ubicación. Intenta desde el Zócalo.': ['We couldn\'t get your location. Try starting from the Zócalo.', 'Impossible d\'obtenir votre position. Essayez depuis le Zócalo.', 'Dein Standort konnte nicht ermittelt werden. Starte am Zócalo.', 'Não foi possível obter sua localização. Tente pelo Zócalo.'],

  // ----------------------------------------------------------------
  // Chat con IA
  // ----------------------------------------------------------------
  'Algo con sombra para ir con niños': ['Something shady to go with kids', 'Un endroit ombragé pour aller avec des enfants', 'Etwas Schattiges für Kinder', 'Algo com sombra para ir com crianças'],
  '¿Dónde como mariscos cerca del Zócalo?': ['Where can I eat seafood near the Zócalo?', 'Où manger des fruits de mer près du Zócalo ?', 'Wo esse ich Meeresfrüchte nahe dem Zócalo?', 'Onde como frutos do mar perto do Zócalo?'],
  'Un museo o lugar gratis': ['A museum or a free place', 'Un musée ou un lieu gratuit', 'Ein Museum oder ein kostenloser Ort', 'Um museu ou lugar grátis'],
  '¿Qué café está abierto ahora?': ['Which café is open now?', 'Quel café est ouvert maintenant ?', 'Welches Café hat jetzt geöffnet?', 'Que café está aberto agora?'],
  'Falta configurar la guía': ['The guide is not set up', 'Le guide n\'est pas configuré', 'Der Guide ist nicht eingerichtet', 'O guia não está configurado'],
  'Los desarrolladores deben agregar GEMINI_API_KEY en env.json y volver a correr la app.': [
    'The developers must add GEMINI_API_KEY to env.json and run the app again.',
    'Les développeurs doivent ajouter GEMINI_API_KEY dans env.json et relancer l\'app.',
    'Die Entwickler müssen GEMINI_API_KEY in env.json eintragen und die App neu starten.',
    'Os desenvolvedores devem adicionar GEMINI_API_KEY no env.json e rodar o app de novo.',
  ],
  '¡Hola! Soy la guía de VeraGo. Cuéntame qué se te antoja hacer en el Centro Histórico y te recomiendo lugares.': [
    'Hi! I\'m the VeraGo guide. Tell me what you feel like doing in the Historic Center and I\'ll recommend places.',
    'Bonjour ! Je suis le guide VeraGo. Dites-moi ce que vous avez envie de faire dans le centre historique et je vous recommanderai des lieux.',
    'Hallo! Ich bin der VeraGo-Guide. Sag mir, worauf du in der Altstadt Lust hast, und ich empfehle dir Orte.',
    'Olá! Sou o guia do VeraGo. Conte o que você quer fazer no Centro Histórico e eu recomendo lugares.',
  ],
  'VeraGo está pensando…': ['VeraGo is thinking…', 'VeraGo réfléchit…', 'VeraGo denkt nach…', 'VeraGo está pensando…'],
  'Estás hablando con una IA. Puede cometer errores.': ['You are talking to an AI. It can make mistakes.', 'Vous parlez à une IA. Elle peut se tromper.', 'Du sprichst mit einer KI. Sie kann Fehler machen.', 'Você está falando com uma IA. Ela pode errar.'],
  'Escribe lo que buscas…': ['Type what you\'re looking for…', 'Écrivez ce que vous cherchez…', 'Schreib, was du suchst…', 'Escreva o que você procura…'],
  'La guía está recibiendo muchas preguntas. Espera un minuto e intenta de nuevo.': [
    'The guide is getting a lot of questions. Wait a minute and try again.',
    'Le guide reçoit beaucoup de questions. Attendez une minute et réessayez.',
    'Der Guide bekommt gerade viele Fragen. Warte eine Minute und versuche es erneut.',
    'O guia está recebendo muitas perguntas. Espere um minuto e tente de novo.',
  ],
  'La guía no pudo responder esa pregunta. Intenta escribirla de otra forma.': [
    'The guide couldn\'t answer that question. Try writing it another way.',
    'Le guide n\'a pas pu répondre. Essayez de formuler autrement.',
    'Der Guide konnte die Frage nicht beantworten. Formuliere sie anders.',
    'O guia não conseguiu responder. Tente escrever de outro jeito.',
  ],
  'La guía no está disponible en este momento. Intenta más tarde.': [
    'The guide is not available right now. Try later.',
    'Le guide n\'est pas disponible pour le moment. Réessayez plus tard.',
    'Der Guide ist gerade nicht verfügbar. Versuche es später.',
    'O guia não está disponível agora. Tente mais tarde.',
  ],
  'La guía respondió algo que no entendimos. Intenta de nuevo.': [
    'The guide replied with something we couldn\'t read. Try again.',
    'Le guide a répondu quelque chose d\'illisible. Réessayez.',
    'Die Antwort des Guides war unverständlich. Versuche es erneut.',
    'O guia respondeu algo que não entendemos. Tente de novo.',
  ],

  // ----------------------------------------------------------------
  // Iniciar sesión / crear cuenta
  // ----------------------------------------------------------------
  'Mostrar contraseña': ['Show password', 'Afficher le mot de passe', 'Passwort anzeigen', 'Mostrar senha'],
  'Ocultar contraseña': ['Hide password', 'Masquer le mot de passe', 'Passwort verbergen', 'Ocultar senha'],
  'Confirma tu correo': ['Confirm your email', 'Confirmez votre e-mail', 'Bestätige deine E-Mail', 'Confirme seu e-mail'],
  'Creamos tu cuenta, pero falta confirmarla. Abre el enlace que te enviamos por correo y después entra aquí con tu contraseña.': [
    'We created your account, but it still needs to be confirmed. Open the link we emailed you and then sign in here with your password.',
    'Votre compte est créé mais doit être confirmé. Ouvrez le lien envoyé par e-mail, puis connectez-vous ici avec votre mot de passe.',
    'Dein Konto wurde erstellt, muss aber noch bestätigt werden. Öffne den Link aus der E-Mail und melde dich dann hier mit deinem Passwort an.',
    'Criamos sua conta, mas falta confirmá-la. Abra o link que enviamos por e-mail e depois entre aqui com sua senha.',
  ],
  'No pudimos continuar': ['We couldn\'t continue', 'Impossible de continuer', 'Es ging nicht weiter', 'Não foi possível continuar'],
  'Crear cuenta': ['Create account', 'Créer un compte', 'Konto erstellen', 'Criar conta'],
  'Con tu cuenta guardamos los sellos de tu pasaporte.': ['Your account keeps your passport stamps.', 'Votre compte garde les tampons de votre passeport.', 'Mit deinem Konto speichern wir deine Pass-Stempel.', 'Com sua conta guardamos os carimbos do seu passaporte.'],
  'Tu nombre': ['Your name', 'Votre nom', 'Dein Name', 'Seu nome'],
  'Correo': ['Email', 'E-mail', 'E-Mail', 'E-mail'],
  'Contraseña': ['Password', 'Mot de passe', 'Passwort', 'Senha'],
  'Escribe tu contraseña': ['Enter your password', 'Saisissez votre mot de passe', 'Gib dein Passwort ein', 'Digite sua senha'],
  'Confirmar contraseña': ['Confirm password', 'Confirmer le mot de passe', 'Passwort bestätigen', 'Confirmar senha'],
  'Las contraseñas no coinciden': ['Passwords don\'t match', 'Les mots de passe ne correspondent pas', 'Die Passwörter stimmen nicht überein', 'As senhas não coincidem'],
  'Entrar': ['Sign in', 'Se connecter', 'Anmelden', 'Entrar'],
  'Al crear tu cuenta aceptas los': ['By creating your account you accept the', 'En créant votre compte, vous acceptez les', 'Mit dem Erstellen deines Kontos akzeptierst du die', 'Ao criar sua conta você aceita os'],
  'Términos de uso': ['Terms of use', 'Conditions d\'utilisation', 'Nutzungsbedingungen', 'Termos de uso'],
  'Aviso de privacidad': ['Privacy notice', 'Avis de confidentialité', 'Datenschutzhinweis', 'Aviso de privacidade'],
  'Ya tengo cuenta': ['I already have an account', 'J\'ai déjà un compte', 'Ich habe schon ein Konto', 'Já tenho conta'],
  'No tengo cuenta: crear una': ['No account? Create one', 'Pas de compte : en créer un', 'Kein Konto? Jetzt erstellen', 'Não tenho conta: criar uma'],
  'No pudimos iniciar sesión. Intenta de nuevo.': ['We couldn\'t sign you in. Try again.', 'Connexion impossible. Réessayez.', 'Anmeldung fehlgeschlagen. Versuche es erneut.', 'Não foi possível entrar. Tente de novo.'],
  'Correo o contraseña incorrectos.': ['Wrong email or password.', 'E-mail ou mot de passe incorrect.', 'E-Mail oder Passwort falsch.', 'E-mail ou senha incorretos.'],
  'Ese correo ya tiene cuenta. Entra con tu contraseña.': ['That email already has an account. Sign in with your password.', 'Cet e-mail a déjà un compte. Connectez-vous avec votre mot de passe.', 'Für diese E-Mail gibt es schon ein Konto. Melde dich mit deinem Passwort an.', 'Esse e-mail já tem conta. Entre com sua senha.'],
  'Tu correo aún no está confirmado. Abre el enlace que te enviamos o pide al administrador que confirme tu cuenta.': [
    'Your email is not confirmed yet. Open the link we sent you or ask the administrator to confirm your account.',
    'Votre e-mail n\'est pas encore confirmé. Ouvrez le lien envoyé ou demandez à l\'administrateur de confirmer votre compte.',
    'Deine E-Mail ist noch nicht bestätigt. Öffne den gesendeten Link oder bitte den Administrator, dein Konto zu bestätigen.',
    'Seu e-mail ainda não foi confirmado. Abra o link que enviamos ou peça ao administrador para confirmar sua conta.',
  ],
  'Se enviaron demasiados correos. Espera unos minutos o pide al administrador que confirme tu cuenta.': [
    'Too many emails were sent. Wait a few minutes or ask the administrator to confirm your account.',
    'Trop d\'e-mails envoyés. Attendez quelques minutes ou demandez à l\'administrateur de confirmer votre compte.',
    'Es wurden zu viele E-Mails gesendet. Warte ein paar Minuten oder bitte den Administrator, dein Konto zu bestätigen.',
    'Foram enviados e-mails demais. Espere alguns minutos ou peça ao administrador para confirmar sua conta.',
  ],
  'La contraseña debe tener al menos 6 caracteres.': ['The password must have at least 6 characters.', 'Le mot de passe doit contenir au moins 6 caractères.', 'Das Passwort muss mindestens 6 Zeichen haben.', 'A senha deve ter pelo menos 6 caracteres.'],
  'No pudimos completar la operación. Intenta de nuevo.': ['We couldn\'t complete that. Try again.', 'Opération impossible. Réessayez.', 'Der Vorgang konnte nicht abgeschlossen werden. Versuche es erneut.', 'Não foi possível concluir. Tente de novo.'],
  // Validaciones de los campos
  'Escribe un correo válido (ej. nombre@correo.com)': ['Enter a valid email (e.g. name@mail.com)', 'Saisissez un e-mail valide (ex. nom@mail.com)', 'Gib eine gültige E-Mail ein (z. B. name@mail.com)', 'Digite um e-mail válido (ex. nome@email.com)'],
  'Usa al menos 8 caracteres': ['Use at least 8 characters', 'Utilisez au moins 8 caractères', 'Mindestens 8 Zeichen', 'Use pelo menos 8 caracteres'],
  'Incluye al menos una letra': ['Include at least one letter', 'Incluez au moins une lettre', 'Mindestens ein Buchstabe', 'Inclua pelo menos uma letra'],
  'Incluye al menos un número': ['Include at least one number', 'Incluez au moins un chiffre', 'Mindestens eine Ziffer', 'Inclua pelo menos um número'],
  'El nombre no lleva números': ['Names can\'t contain numbers', 'Le nom ne contient pas de chiffres', 'Der Name darf keine Ziffern enthalten', 'O nome não leva números'],
  'Escribe tu nombre completo': ['Enter your full name', 'Saisissez votre nom complet', 'Gib deinen vollständigen Namen ein', 'Digite seu nome completo'],
  'Escribe tu nombre': ['Enter your name', 'Saisissez votre nom', 'Gib deinen Namen ein', 'Digite seu nome'],
  'El nombre debe empezar con una letra': ['The name must start with a letter', 'Le nom doit commencer par une lettre', 'Der Name muss mit einem Buchstaben beginnen', 'O nome deve começar com uma letra'],
  'Escribe nombre y apellido': ['Enter first and last name', 'Saisissez prénom et nom', 'Gib Vor- und Nachnamen ein', 'Digite nome e sobrenome'],

  // ----------------------------------------------------------------
  // Ajustes
  // ----------------------------------------------------------------
  'Mi cuenta': ['My account', 'Mon compte', 'Mein Konto', 'Minha conta'],
  'Nombre guardado.': ['Name saved.', 'Nom enregistré.', 'Name gespeichert.', 'Nome salvo.'],
  '¿Borrar tu cuenta para siempre?': ['Delete your account forever?', 'Supprimer votre compte définitivement ?', 'Dein Konto endgültig löschen?', 'Apagar sua conta para sempre?'],
  'Se borran tu cuenta, tu nombre y todos tus sellos. Si tienes un negocio: si aún no se aprobaba, se borra; si ya estaba en la app, se oculta.\n\nEsto no se puede deshacer.': [
    'Your account, your name and all your stamps will be deleted. If you have a business: if it was not approved yet, it is deleted; if it was already in the app, it is hidden.\n\nThis cannot be undone.',
    'Votre compte, votre nom et tous vos tampons seront supprimés. Si vous avez un commerce : s\'il n\'était pas encore approuvé, il est supprimé ; s\'il était déjà dans l\'app, il est masqué.\n\nCette action est irréversible.',
    'Dein Konto, dein Name und alle Stempel werden gelöscht. Hast du ein Geschäft: Wenn es noch nicht freigegeben war, wird es gelöscht; war es schon in der App, wird es ausgeblendet.\n\nDas kann nicht rückgängig gemacht werden.',
    'Sua conta, seu nome e todos os seus carimbos serão apagados. Se você tem um negócio: se ainda não estava aprovado, é apagado; se já estava no app, fica oculto.\n\nIsso não pode ser desfeito.',
  ],
  'Borrar para siempre': ['Delete forever', 'Supprimer définitivement', 'Endgültig löschen', 'Apagar para sempre'],
  'Tu cuenta se borró.': ['Your account was deleted.', 'Votre compte a été supprimé.', 'Dein Konto wurde gelöscht.', 'Sua conta foi apagada.'],
  'No pudimos borrar tu cuenta. Intenta de nuevo.': ['We couldn\'t delete your account. Try again.', 'Impossible de supprimer votre compte. Réessayez.', 'Dein Konto konnte nicht gelöscht werden. Versuche es erneut.', 'Não foi possível apagar sua conta. Tente de novo.'],
  'Una cuenta de administrador no se borra desde la app. Pídeselo a los desarrolladores.': [
    'An administrator account can\'t be deleted from the app. Ask the developers.',
    'Un compte administrateur ne se supprime pas depuis l\'app. Demandez aux développeurs.',
    'Ein Administratorkonto kann nicht in der App gelöscht werden. Frag die Entwickler.',
    'Uma conta de administrador não é apagada pelo app. Peça aos desenvolvedores.',
  ],
  'Falta actualizar la base de datos (correr el SQL 016). Avisa a los desarrolladores.': [
    'The database needs an update (run SQL 016). Let the developers know.',
    'La base de données doit être mise à jour (SQL 016). Prévenez les développeurs.',
    'Die Datenbank muss aktualisiert werden (SQL 016). Sag den Entwicklern Bescheid.',
    'Falta atualizar o banco de dados (SQL 016). Avise os desenvolvedores.',
  ],
  'No pudimos guardar tu nombre. Intenta de nuevo.': ['We couldn\'t save your name. Try again.', 'Impossible d\'enregistrer votre nom. Réessayez.', 'Dein Name konnte nicht gespeichert werden. Versuche es erneut.', 'Não foi possível salvar seu nome. Tente de novo.'],
  'Comerciante': ['Merchant', 'Commerçant', 'Händler', 'Comerciante'],
  'Administrador': ['Administrator', 'Administrateur', 'Administrator', 'Administrador'],
  'Rol: {rol}': ['Role: {rol}', 'Rôle : {rol}', 'Rolle: {rol}', 'Função: {rol}'],
  'Mi nombre': ['My name', 'Mon nom', 'Mein Name', 'Meu nome'],
  'Guardando…': ['Saving…', 'Enregistrement…', 'Speichern…', 'Salvando…'],
  'Guardar nombre': ['Save name', 'Enregistrer le nom', 'Name speichern', 'Salvar nome'],
  'Mis intereses': ['My interests', 'Mes centres d\'intérêt', 'Meine Interessen', 'Meus interesses'],
  'Se marcan solos al pedir una ruta. Se guardan en este celular.': [
    'They are pre-selected when you ask for a route. Saved on this phone.',
    'Ils sont présélectionnés pour vos itinéraires. Enregistrés sur ce téléphone.',
    'Sie werden bei der Routenplanung vorausgewählt. Auf diesem Handy gespeichert.',
    'São marcados sozinhos ao pedir uma rota. Ficam salvos neste celular.',
  ],
  'Guía de la app': ['App guide', 'Guide de l\'app', 'App-Anleitung', 'Guia do app'],
  'Ver la guía de la app otra vez': ['See the app guide again', 'Revoir le guide de l\'app', 'App-Anleitung erneut ansehen', 'Ver o guia do app de novo'],
  'Privacidad': ['Privacy', 'Confidentialité', 'Datenschutz', 'Privacidade'],
  'Qué guardamos': ['What we store', 'Ce que nous gardons', 'Was wir speichern', 'O que guardamos'],
  '• Tu correo y tu nombre.\n• Los sellos que ganas (lugar y fecha).': [
    '• Your email and your name.\n• The stamps you earn (place and date).',
    '• Votre e-mail et votre nom.\n• Les tampons que vous gagnez (lieu et date).',
    '• Deine E-Mail und dein Name.\n• Die Stempel, die du sammelst (Ort und Datum).',
    '• Seu e-mail e seu nome.\n• Os carimbos que você ganha (lugar e data).',
  ],
  'Qué NO guardamos': ['What we DON\'T store', 'Ce que nous NE gardons PAS', 'Was wir NICHT speichern', 'O que NÃO guardamos'],
  '• Tu ubicación: se usa en tu celular para el mapa (si das permiso). Solo el inicio de una ruta desde "Mi ubicación" se envía para dibujar el camino.\n• No te seguimos en segundo plano.': [
    '• Your location: it is used on your phone for the map (if you allow it). Only the start of a route from "My location" is sent to draw the path.\n• We don\'t track you in the background.',
    '• Votre position : elle sert sur votre téléphone pour la carte (si vous l\'autorisez). Seul le départ d\'un itinéraire depuis « Ma position » est envoyé pour tracer le chemin.\n• Nous ne vous suivons pas en arrière-plan.',
    '• Dein Standort: Er wird auf deinem Handy für die Karte genutzt (wenn du es erlaubst). Nur der Start einer Route ab „Mein Standort“ wird gesendet, um den Weg zu zeichnen.\n• Wir verfolgen dich nicht im Hintergrund.',
    '• Sua localização: é usada no seu celular para o mapa (se você permitir). Só o início de uma rota a partir de "Minha localização" é enviado para traçar o caminho.\n• Não seguimos você em segundo plano.',
  ],
  'Tus intereses y tu idioma se guardan solo en este celular.': [
    'Your interests and language are saved only on this phone.',
    'Vos centres d\'intérêt et votre langue sont enregistrés uniquement sur ce téléphone.',
    'Deine Interessen und deine Sprache werden nur auf diesem Handy gespeichert.',
    'Seus interesses e seu idioma ficam salvos só neste celular.',
  ],
  'Legal y confianza': ['Legal & trust', 'Mentions légales et confiance', 'Rechtliches & Vertrauen', 'Legal e confiança'],
  'Cerrar sesión': ['Sign out', 'Se déconnecter', 'Abmelden', 'Sair'],
  'Una cuenta de administrador no se borra desde la app.': ['An administrator account can\'t be deleted from the app.', 'Un compte administrateur ne se supprime pas depuis l\'app.', 'Ein Administratorkonto kann nicht in der App gelöscht werden.', 'Uma conta de administrador não é apagada pelo app.'],
  'Borrar mi cuenta': ['Delete my account', 'Supprimer mon compte', 'Mein Konto löschen', 'Apagar minha conta'],

  // ----------------------------------------------------------------
  // Documentos legales (títulos y resúmenes; el texto se traduce con IA)
  // ----------------------------------------------------------------
  'Contacta al equipo de VeraGo.': ['Contact the VeraGo team.', 'Contactez l\'équipe VeraGo.', 'Kontaktiere das VeraGo-Team.', 'Fale com a equipe do VeraGo.'],
  'Escríbenos a {correo}.': ['Write to us at {correo}.', 'Écrivez-nous à {correo}.', 'Schreib uns an {correo}.', 'Escreva para {correo}.'],
  'Las reglas para usar VeraGo como turista, tu seguridad y nuestra responsabilidad.': [
    'The rules for using VeraGo as a visitor, your safety and our responsibility.',
    'Les règles pour utiliser VeraGo comme visiteur, votre sécurité et notre responsabilité.',
    'Die Regeln für die Nutzung von VeraGo als Besucher, deine Sicherheit und unsere Verantwortung.',
    'As regras para usar o VeraGo como turista, sua segurança e nossa responsabilidade.',
  ],
  'Qué datos pedimos, para qué, con quién se comparten y cómo corregirlos o borrarlos.': [
    'What data we ask for, why, who it is shared with and how to correct or delete it.',
    'Quelles données nous demandons, pourquoi, avec qui elles sont partagées et comment les corriger ou les supprimer.',
    'Welche Daten wir erfragen, wofür, mit wem sie geteilt werden und wie du sie korrigierst oder löschst.',
    'Que dados pedimos, para quê, com quem são compartilhados e como corrigi-los ou apagá-los.',
  ],
  'Términos para negocios': ['Terms for businesses', 'Conditions pour les commerces', 'Bedingungen für Geschäfte', 'Termos para negócios'],
  'Lo que acepta un negocio al registrarse en VeraGo.': ['What a business accepts when registering on VeraGo.', 'Ce qu\'accepte un commerce en s\'inscrivant sur VeraGo.', 'Was ein Geschäft bei der Registrierung in VeraGo akzeptiert.', 'O que um negócio aceita ao se cadastrar no VeraGo.'],
  'Reglas operativas': ['Operating rules', 'Règles de fonctionnement', 'Betriebsregeln', 'Regras operacionais'],
  'Cómo trabaja VeraGo: aprobaciones, sellos, cambios, reportes y emergencias.': [
    'How VeraGo works: approvals, stamps, changes, reports and emergencies.',
    'Comment fonctionne VeraGo : validations, tampons, modifications, signalements et urgences.',
    'So arbeitet VeraGo: Freigaben, Stempel, Änderungen, Meldungen und Notfälle.',
    'Como o VeraGo funciona: aprovações, carimbos, mudanças, relatos e emergências.',
  ],
  '¿Cómo funciona VeraGo?': ['How does VeraGo work?', 'Comment fonctionne VeraGo ?', 'Wie funktioniert VeraGo?', 'Como o VeraGo funciona?'],
  'Por qué puedes confiar en los sellos, los negocios y tus datos.': [
    'Why you can trust the stamps, the businesses and your data.',
    'Pourquoi vous pouvez faire confiance aux tampons, aux commerces et à vos données.',
    'Warum du den Stempeln, den Geschäften und deinen Daten vertrauen kannst.',
    'Por que você pode confiar nos carimbos, nos negócios e nos seus dados.',
  ],
};
