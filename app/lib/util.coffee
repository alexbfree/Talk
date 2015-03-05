config = require 'lib/config'

SHORT_WORDS = ['and', 'to', 'the']

CLASSIFICATION_DOMINANCE_THRESHOLD = 10
CLASSIFICATION_COMPLETE_THRESHOLD = 25
CLASSIFICATION_BLANK_THRESHOLD = 5

self =

  buildCrowdData: (response) =>
    debugger
    crowdData = {}
    if response.metadata
      crowdData.allClassificationData = self.getAllClassifications response.metadata.counters
      crowdData.maxClassificationID = self.getMaxClassificationID response.metadata.counters
      crowdData.maxClassificationData = {}
      crowdData.maxClassificationData.voters = 0
      crowdData.active = false
      if (crowdData.maxClassificationID)
        crowdData.maxClassificationVoters = response.metadata.counters[crowdData.maxClassificationID]
        crowdData.maxClassificationData = self.getClassificationDataFromCountersEntry crowdData.maxClassificationID, crowdData.maxClassificationVoters
        crowdData.maxClassificationNumberOfDifferentSpecies = crowdData.maxClassificationData.speciesData.length
        crowdData.dominantClassificationID = self.getDominantClassificationID response.metadata.counters, CLASSIFICATION_DOMINANCE_THRESHOLD
      if response.classification_count >= CLASSIFICATION_COMPLETE_THRESHOLD
        crowdData.state = "complete"
        crowdData.message = "This subject has been completely classified"
      else if response.classification_count == 0
        crowdData.active = true
        crowdData.state = "unclassified"
        crowdData.message = "This subject has yet to be classified"
        crowdData.min_classifications_needed = CLASSIFICATION_DOMINANCE_THRESHOLD
      else if crowdData.dominantClassificationID
        crowdData.dominantClassificationVoters = response.metadata.counters[crowdData.dominantClassificationID]
        crowdData.dominantClassificationData = self.getClassificationDataFromCountersEntry crowdData.dominantClassificationID, crowdData.dominantClassificationVoters
        crowdData.dominantClassificationNumberOfDifferentSpecies = Object.keys(crowdData.dominantClassificationData.speciesData).length
        if crowdData.dominantClassificationID == 'blank'
          crowdData.state = "blank_by_consensus"
          crowdData.message = "The crowd has reached agreement that there are no animals present in this subject"
        else
          if crowdData.dominantClassificationNumberOfDifferentSpecies == 1
            crowdData.dominantClassificationSoleSpeciesID = crowdData.dominantClassificationID
            crowdData.dominantClassificationSoleSpeciesName = self.getHumanFriendlySpecies crowdData.dominantClassificationID
            crowdData.state = "one_sole_species_by_consensus"
            crowdData.message = "The crowd has reached agreement that this subject contains one or more "+crowdData.dominantClassificationSoleSpeciesName
          else
            crowdData.state = "several_species_by_consensus"
            crowdData.message = "The crowd has reached agreement that this subject contains the following species"
      else
        if response.metadata.counters.hasOwnProperty 'blank'
          if Object.keys(response.metadata.counters).length == 1
            if response.metadata.counters['blank'] < CLASSIFICATION_BLANK_THRESHOLD
              crowdData.active = true
              crowdData.state = "active_but_nearly_blank"
              crowdData.message = "The crowd is still classifying this subject, but so far it appears to contain no animals"
              crowdData.min_classifications_needed = CLASSIFICATION_BLANK_THRESHOLD - response.metadata.counters['blank']
            else
              crowdData.state = "unanimously_blank"
              crowdData.message = "The crowd unanimously agrees that this subject contains no animals"
          else
            if Object.keys(response.metadata.counters).length == 2
              crowdData.active = true
              crowdData.state = "active_either_blank_or_agreed_animals"
              crowdData.message = "The crowd is still classifying this subject. There is disagreement as to whether any animals are present, but not as to which species are present"
              crowdData.min_classifications_needed = CLASSIFICATION_DOMINANCE_THRESHOLD - crowdData.maxClassificationData.voters
            else
              crowdData.active = true
              crowdData.state = "active_either_blank_or_uncertain_animals"
              crowdData.message = "The crowd is still classifying this subject. There is disagreement as to whether any animals are present, and as to which species are present"
              crowdData.min_classifications_needed = CLASSIFICATION_DOMINANCE_THRESHOLD - crowdData.maxClassificationData.voters
        else
            if Object.keys(response.metadata.counters).length == 1
              crowdData.active = true
              crowdData.state = "active_but_agreed_animals"
              crowdData.message = "The crowd is still classifying this subject. There does seem to be one or more animals present. So far, there is agreement upon which species are present"
              crowdData.min_classifications_needed = CLASSIFICATION_DOMINANCE_THRESHOLD - crowdData.maxClassificationData.voters
            else
              crowdData.active = true
              crowdData.state = "active_but_uncertain_animals"
              crowdData.message = "The crowd is still classifying this subject. There does seem to be one or more animals present. There is disagreement as to which species are present"
              crowdData.min_classifications_needed = CLASSIFICATION_DOMINANCE_THRESHOLD - crowdData.maxClassificationData.voters
    else
      crowdData.active = true
      crowdData.state = "active_unknown"
      crowdData.message = "This image has not yet been classified by anyone. Nothing is known about this image"
      crowdData.min_classifications_needed = CLASSIFICATION_DOMINANCE_THRESHOLD
    crowdData

  getMaxClassificationID: (metadata_counters) ->
    for maxKey of metadata_counters
      break
    for key of metadata_counters
        if metadata_counters.hasOwnProperty key
            if metadata_counters[key] > metadata_counters[maxKey]
              maxKey = key
    maxKey

  getDominantClassificationID: (metadata_counters, threshold = CLASSIFICATION_DOMINANCE_THRESHOLD) ->
    maxClassification = self.getMaxClassificationID metadata_counters
    if metadata_counters[maxClassification] >= threshold
      maxClassification
    else
      false

  getSpeciesDataForClassificationID: (classificationID) ->
    specieses = classificationID.split '-'
    speciesData = {}
    for species in specieses
        speciesId = species
        speciesName = self.getHumanFriendlySpecies species
        speciesData[speciesId] = speciesName
    speciesData

  getClassificationDataFromCountersEntry: (combinedClassificationID, voters) ->
    classification = {}
    classification.speciesData = self.getSpeciesDataForClassificationID combinedClassificationID
    classification.voters = voters
    classification

  getAllClassifications: (metadata_counters) ->
    classifications = []
    for combinedClassificationID, voters of metadata_counters
      classifications.push self.getClassificationDataFromCountersEntry combinedClassificationID, voters
    classifications

  getHumanFriendlySpecies: (species, count = 2) ->
    if species in ['wildebeest', 'buffalo', 'impala', 'hartebeest', 'topi']
      species
    else if species in ['elephant', 'warthog', 'reedbuck', 'human', 'giraffe', 'waterbuck',
                        'aardvark', 'bushbuck', 'cheetah', 'baboon', 'jackal', 'serval',
                        'bat', 'caracal', 'civet', 'duiker', 'genet', 'hare', 'leopard',
                        'mongoose', 'porcupine', 'steenbok', 'eland', 'vulture', 'wildcat',
                        'zorilla', 'zebra']
      self.pluralize(count, species, species + 's')
    else if species in ['hippopotamus', 'rhinoceros', 'ostrich']
      self.pluralize(count, species, species + 'es')
    else if species is 'cattle'
      self.pluralize(count, 'cow', 'cattle')
    else if species in ['reptiles','rodents']
      self.pluralize(count, species.slice(0, - 1), species)
    else if species is 'gazellethomsons'
      self.pluralize(count, "Thomson's gazelle", "Thomson's gazelles")
    else if species is 'gazellegrants'
      self.pluralize(count, "Grant's gazelle", "Grant's gazelles")
    else if species in 'otherbird'
      self.pluralize(count, "bird (other)", "birds (other)")
    else if species is 'dikdik'
      self.pluralize(count, "dik-dik", "dik-diks")
    else if species is 'honeybadger'
      self.pluralize(count, "honey badger", "honey badgers")
    else if species is 'hyenaspotted'
      "spotted hyena"
    else if species is 'hyenastriped'
      "striped hyena"
    else if species is 'lionfemale'
      self.pluralize(count, "female lion", "female lions")
    else if species is 'lionmale'
      self.pluralize(count, "male lion", "male lions")
    else if species is 'guineafowl'
      "guinea fowl"
    else if species is 'koribustard'
      self.pluralize(count, "kori bustard", "kori bustards")
    else if species is 'batearedfox'
      self.pluralize(count, "bat-eared fox", "bat-eared foxes")
    else if species is 'aardwolf'
      self.pluralize(count, "aardwolf", "aardwolves")
    else if species is 'secretarybird'
      self.pluralize(count, "secretary bird", "secretary birds")
    else if species is 'insectspider'
      self.pluralize(count, "spider or insect", "spiders or insects")
    else if species is 'vervetmonkey'
      self.pluralize(count, "vervet monkey", "vervet monkeys")
    else if species is 'blank'
      'blank'
    else
      self.pluralize(count, species, species + 's') 

  capitalize: (string) ->
    string.replace /^(\w)/, (c) -> c.toUpperCase()

  truther: (bool) ->
    if bool then 'yes' else 'no'

  focusCollectionFor: (type) ->
    if type is 'Board'
      'boards'
    else if /Subject$/.test(type)
      'subjects'
    else if /Group$/.test(type)
      'groups'
    else if type in ['SubjectSet', 'KeywordSet']
      'collections'

  singularize: (word) ->
    word.replace /s$/, ''

  pluralize: (number, singular, plural) ->
    if number > 1 or number is 0 then plural else singular

  truncate: (text, length) ->
    return text unless typeof text is 'string'
    return text if text.length <= length
    text.substring(0, length).replace(/\s?\w+$/, '') + '...'

  titleize: (text) ->
    # There's probably a million holes in this
    text.replace /([-_ ]|^)(\w)/g, (match, separator, letter) ->
      " #{ letter.toUpperCase() }"
    .trim()
    .split(' ')
    .map (word, index) ->
      return word if index is 0
      if word.toLowerCase() in SHORT_WORDS
        word.toLowerCase()
      else
        word
    .join(' ')

  formatNumber: (n) ->
    return n unless n
    n.toString().replace /(\d)(?=(\d{3})+(?!\d))/g, '$1,'

  equalObjects: (a, b) ->
    for own key, val of a
      return false unless key of b
      
      if val is Object(val)
        return false unless arguments.callee(val, b[key])
      else
        return false if b[key] isnt val
    
    for own key, val of b
      return false unless key of a
      
      if val is Object(val)
        return false unless arguments.callee(val, a[key])
      else
        return false if a[key] isnt val
    
    true

  getCategoryLabel: (category) ->
    categoryLabels = config?.app?.categoryLabels || {}
    if category of categoryLabels then categoryLabels[category] else category

module.exports = self