package com.github.csukuangfj.piper.phonemize.demo

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.github.csukuangfj.piper.phonemize.*

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme {
                Surface(modifier = Modifier.fillMaxSize()) {
                    PhonemizeScreen()
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PhonemizeScreen() {
    val context = androidx.compose.ui.platform.LocalContext.current
    var initialized by remember { mutableStateOf(false) }
    var initError by remember { mutableStateOf<String?>(null) }
    var selectedLanguage by remember { mutableStateOf("en") }
    var inputText by remember { mutableStateOf("") }
    var outputText by remember { mutableStateOf("") }
    var expanded by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        try {
            piperPhonemizeInitialize(context)
            initialized = true
        } catch (e: Exception) {
            initError = e.message
        }
    }

    val languages = remember { getLanguages() }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
            .verticalScroll(rememberScrollState()),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Text(
            text = "Piper Phonemize Demo",
            style = MaterialTheme.typography.headlineMedium
        )

        if (initError != null) {
            Text(text = "Init error: $initError", color = MaterialTheme.colorScheme.error)
        } else if (!initialized) {
            CircularProgressIndicator()
            Text(text = "Initializing espeak-ng...")
        }

        // Language dropdown
        ExposedDropdownMenuBox(
            expanded = expanded,
            onExpandedChange = { expanded = !expanded }
        ) {
            TextField(
                value = "${languages.find { it.first == selectedLanguage }?.second ?: selectedLanguage} ($selectedLanguage)",
                onValueChange = {},
                readOnly = true,
                label = { Text("Language") },
                trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
                modifier = Modifier.menuAnchor().fillMaxWidth()
            )
            ExposedDropdownMenu(
                expanded = expanded,
                onDismissRequest = { expanded = false }
            ) {
                languages.forEach { (code, name) ->
                    DropdownMenuItem(
                        text = { Text("$name ($code)") },
                        onClick = {
                            selectedLanguage = code
                            expanded = false
                        }
                    )
                }
            }
        }

        // Example and Clear buttons
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Button(
                onClick = {
                    val examples = getExampleTexts()
                    val texts = examples[selectedLanguage] ?: examples["en"]!!
                    inputText = texts.joinToString(" ")
                },
                enabled = initialized
            ) {
                Text("Example")
            }
            OutlinedButton(
                onClick = {
                    inputText = ""
                    outputText = ""
                }
            ) {
                Text("Clear")
            }
        }

        // Input
        TextField(
            value = inputText,
            onValueChange = { inputText = it },
            label = { Text("Input text") },
            modifier = Modifier.fillMaxWidth().heightIn(min = 100.dp),
            maxLines = 6
        )

        // Phonemize button
        Button(
            onClick = {
                val startMs = System.currentTimeMillis()
                val wordCount = inputText.trim().split("\\s+".toRegex()).filter { it.isNotEmpty() }.size
                val result = piperPhonemizeText(inputText, selectedLanguage)
                val elapsedMs = System.currentTimeMillis() - startMs
                if (result != null) {
                    val sb = StringBuilder()
                    sb.appendLine("Words: $wordCount | Time: ${elapsedMs}ms")
                    sb.appendLine("Sentences: ${result.numSentences}")
                    sb.appendLine()
                    for (i in 0 until result.numSentences) {
                        val ipa = result.getPhonemesAsString(i)
                        sb.appendLine("Sentence ${i + 1}: $ipa")
                    }
                    outputText = sb.toString().trim()
                    result.close()
                } else {
                    outputText = "Phonemization failed"
                }
            },
            enabled = initialized && inputText.isNotBlank()
        ) {
            Text("Phonemize")
        }

        // Output
        if (outputText.isNotEmpty()) {
            Text(text = "Output:", style = MaterialTheme.typography.titleMedium)
            Text(text = outputText, modifier = Modifier.fillMaxWidth())
        }
    }
}

data class Lang(val code: String, val name: String)

fun getLanguages(): List<Pair<String, String>> = listOf(
    "af" to "Afrikaans", "am" to "Armenian", "an" to "Aragonese",
    "ar" to "Arabic", "as" to "Assamese", "az" to "Azerbaijani",
    "ba" to "Bashkir", "be" to "Belarusian", "bg" to "Bulgarian",
    "bn" to "Bengali", "bpy" to "Bishnupriya Manipuri", "bs" to "Bosnian",
    "ca" to "Catalan", "chr" to "Cherokee", "cmn" to "Mandarin Chinese",
    "cs" to "Czech", "cv" to "Chuvash", "cy" to "Welsh",
    "da" to "Danish", "de" to "German", "el" to "Greek",
    "en" to "English", "eo" to "Esperanto", "es" to "Spanish",
    "et" to "Estonian", "eu" to "Basque", "fa" to "Persian",
    "fi" to "Finnish", "fr" to "French", "ga" to "Irish",
    "gd" to "Scottish Gaelic", "gn" to "Guarani", "grc" to "Ancient Greek",
    "gu" to "Gujarati", "hak" to "Hakka Chinese", "haw" to "Hawaiian",
    "he" to "Hebrew", "hi" to "Hindi", "hr" to "Croatian",
    "ht" to "Haitian Creole", "hu" to "Hungarian", "hy" to "Armenian",
    "ia" to "Interlingua", "id" to "Indonesian", "io" to "Ido",
    "is" to "Icelandic", "it" to "Italian", "ja" to "Japanese",
    "jbo" to "Lojban", "ka" to "Georgian", "kk" to "Kazakh",
    "kl" to "Greenlandic", "kn" to "Kannada", "ko" to "Korean",
    "kok" to "Konkani", "ku" to "Kurdish", "ky" to "Kyrgyz",
    "la" to "Latin", "lb" to "Luxembourgish", "lfn" to "Lingua Franca Nova",
    "lt" to "Lithuanian", "lv" to "Latvian", "mi" to "Maori",
    "mk" to "Macedonian", "ml" to "Malayalam", "mr" to "Marathi",
    "ms" to "Malay", "mt" to "Maltese", "mto" to "Mazatec",
    "my" to "Burmese", "nci" to "Classical Nahuatl", "ne" to "Nepali",
    "nl" to "Dutch", "no" to "Norwegian", "nog" to "Nogai",
    "om" to "Oromo", "or" to "Oriya", "pa" to "Punjabi",
    "pap" to "Papiamento", "piqd" to "Klingon", "pl" to "Polish",
    "pt" to "Portuguese", "py" to "Pytdf", "qdb" to "Qdb",
    "qu" to "Quechua", "quc" to "K'iche'", "qya" to "Quenya",
    "ro" to "Romanian", "ru" to "Russian", "sd" to "Sindhi",
    "shn" to "Shan", "si" to "Sinhala", "sjn" to "Sindarin",
    "sk" to "Slovak", "sl" to "Slovenian", "smj" to "Lule Sami",
    "sq" to "Albanian", "sr" to "Serbian", "sv" to "Swedish",
    "sw" to "Swahili", "ta" to "Tamil", "te" to "Telugu",
    "th" to "Thai", "tk" to "Turkmen", "tn" to "Tswana",
    "tr" to "Turkish", "tt" to "Tatar", "ug" to "Uyghur",
    "uk" to "Ukrainian", "ur" to "Urdu", "uz" to "Uzbek",
    "vi" to "Vietnamese", "yue" to "Cantonese"
)

fun getExampleTexts(): Map<String, List<String>> = mapOf(
    "en" to listOf("The weather is beautiful today.", "I would like to go for a walk in the park.", "The birds are singing and the sun is shining brightly."),
    "zh" to listOf("今天天气很好。", "我想去公园散步。", "鸟儿在歌唱，阳光明媚。"),
    "cmn" to listOf("今天天气很好。", "我想去公园散步。", "鸟儿在歌唱，阳光明媚。"),
    "ja" to listOf("今日はとても良い天気です。", "公園を散步したいです。", "小鳥が歌っていて、太陽が明るく輝いています。"),
    "ko" to listOf("오늘 날씨가 좋습니다.", "공원을 산책하고 싶습니다.", "새들이 노래하고 태양이 밝게 빛나고 있습니다."),
    "fr" to listOf("Le temps est magnifique aujourd'hui.", "Je voudrais me promener dans le parc.", "Les oiseaux chantent et le soleil brille."),
    "de" to listOf("Das Wetter ist heute wunderschön.", "Ich möchte im Park spazieren gehen.", "Die Vögel singen und die Sonne scheint hell."),
    "es" to listOf("El clima es hermoso hoy.", "Me gustaría dar un paseo por el parque.", "Los pájaros cantan y el sol brilla con fuerza."),
    "ru" to listOf("Сегодня прекрасная погода.", "Я хотел бы прогуляться по парку.", "Птицы поют и солнце ярко светит."),
    "pt" to listOf("O tempo está lindo hoje.", "Eu gostaria de dar um passeio no parque.", "Os pássaros estão cantando e o sol brilha intensamente."),
    "ar" to listOf("الطقس جميل اليوم.", "أريد أن أمشي في الحديقة.", "الطير تغني والشمس مشرقة."),
    "hi" to listOf("आज मौसम बहुत अच्छा है.", "मैं पार्क में टहलना चाहता हूँ.", "पक्षी गा रहे हैं और सूरज चमक रहा है."),
    "it" to listOf("Il tempo è bellissimo oggi.", "Vorrei fare una passeggiata nel parco.", "Gli uccelli cantano e il sole splende."),
    "nl" to listOf("Het weer is prachtig vandaag.", "Ik wil graag in het park wandelen.", "De vogels zingen en de zon schijnt helder."),
    "pl" to listOf("Pogoda jest dziś piękna.", "Chciałbym pójść na spacer do parku.", "Ptaki śpiewają i słońce jasno świeci."),
    "sv" to listOf("Vädret är underbart idag.", "Jag skulle vilja promenera i parken.", "Fåglarna sjunger och solen skiner."),
    "tr" to listOf("Hava bugün çok güzel.", "Parkta yürümek istiyorum.", "Kuşlar ötüyor ve güneş parlak bir şekilde parlıyor."),
    "vi" to listOf("Hôm nay thời tiết rất đẹp.", "Tôi muốn đi dạo trong công viên.", "Chim hót và mặt trời chiếu sáng."),
    "th" to listOf("วันนี้อากาศสวยงาม", "ฉันอยากไปเดินเล่นในสวนสาธารณะ", "นกร้องเพลงและดวงอาทิตย์ส่องสว่าง"),
    "uk" to listOf("Сьогодні прекрасна погода.", "Я хотів би прогулятися по парку.", "Птахи співають і сонце яскраво світить."),
    "cs" to listOf("Počasí je dnes nádherné.", "Chtěl bych se projít v parku.", "Ptáci zpívají a slunce jasně svítí."),
    "el" to listOf("Ο καιρός είναι υπέροχος σήμερα.", "Θα ήθελα να κάνω μια βόλτα στο πάρκο.", "Τα πουλιά τραγουδούν και ο ήλιος λάμπει."),
    "hu" to listOf("Az idő ma gyönyörű.", "Szeretnék sétálni a parkban.", "A madarak énekelnek és a nap ragyogóan süt."),
    "ro" to listOf("Vremea este frumoasă astăzi.", "Aș vrea să mă plimb în parc.", "Păsările cântă și soarele strălucește."),
    "da" to listOf("Vejret er smukt i dag.", "Jeg vil gerne gå en tur i parken.", "Fuglene synger og solen skinner."),
    "fi" to listOf("Sää on kaunis tänään.", "Haluaisin kävellä puistossa.", "Linnut laulavat aurinko paistaa kirkkaasti."),
    "no" to listOf("Været er nydelig i dag.", "Jeg vil gjerne gå en tur i parken.", "Fuglene synger og solen skinner."),
    "sk" to listOf("Počasie je dnes nádherné.", "Chcel by som sa prejsť v parku.", "Spievajú vtáky a slnko jasne svieti."),
    "bg" to listOf("Времето е прекрасно днес.", "Искам да се разходя в парка.", "Птиците пеят и слънцето грее ярко."),
    "sr" to listOf("Vreme je danas prelepo.", "Voleo bih da prošetam parkom.", "Ptice pevaju i sunce sija."),
    "hr" to listOf("Vrijeme je danas prekrasno.", "Volio bih prošetati parkom.", "Ptice pjevaju i sunce sja."),
    "id" to listOf("Cuaca hari ini sangat indah.", "Saya ingin berjalan-jalan di taman.", "Burung-burung bernyanyi dan matahari bersinar terang."),
    "ms" to listOf("Cuaca hari ini sangat cantik.", "Saya ingin berjalan di taman.", "Burung-burung bernyanyi dan matahari bersinar terang."),
    "sw" to listOf("Hali ya hewa ni nzuri leo.", "Ningependa kutembea katika bustani.", "Ndege wanaimba na jua linaangaza."),
    "af" to listOf("Die weer is vandag pragtig.", "Ek wil graag in die park gaan stap.", "Die voëls sing en die son skyn helder."),
    "am" to listOf("የአየር ሁኔታ ዛሬ ቆንጆ ነው።", "በፓርኩ ውስጥ መራመድ እፈልጋለሁ።", "ወፎች ይዘፍናሉ ፣ ፀሐይም ብሩህ ብሎ ይበራል።"),
    "ar" to listOf("الطقس جميل اليوم.", "أريد أن أمشي في الحديقة.", "الطير تغني والشمس مشرقة."),
    "as" to listOf("আজিৰ বতৰ ধুনীয়া।", "মই উদ্যানত খেদিব বিচাৰিম।", "চৰাই গাই আছে আৰু সূৰ্য্য উজ্জ্বলভাৱে জ্বলিছে।"),
    "az" to listOf("Bu gün hava çox gözəldir.", "Parkda gəzmək istəyirəm.", "Quşlar oxuyur və günəş parlaq şəkildə parlayır."),
    "ba" to listOf("Бөгөн һауа шәп.", "Паркта йөрөргә теләйем.", "Ҡоштар йырлай һәм ҡояш яҡты нурландыра."),
    "be" to listOf("Сёння цудоўнае надвор'е.", "Я б хацёў прагуляцца па парку.", "Птушкі спяваюць і сонца ярка свеціць."),
    "bn" to listOf("আজ আবহাওয়া খুব সুন্দর।", "আমি পার্কে হাঁটতে চাই।", "পাখি গাইছে এবং সূর্য উজ্জ্বলভাবে জ্বলছে।"),
    "bs" to listOf("Vrijeme je danas prekrasno.", "Volio bih prošetati parkom.", "Ptice pjevaju i sunce sja."),
    "ca" to listOf("El temps és magnífic avui.", "M'agradaria fer un passeig pel parc.", "Els ocells canten i el sol brilla."),
    "cy" to listOf("Mae'r tywydd yn hyfryd heddiw.", "Hoffwn fynd am dro yn y parc.", "Mae'r adar yn canu a'r haul yn tywynnu'n llachar."),
    "eo" to listOf("La vetero estas bela hodiaŭ.", "Mi ŝirus promeni en la parko.", "La birdoj kantas kaj la suno brilas."),
    "et" to listOf("Täna on ilus ilm.", "Tahaksin pargis jalutada.", "Linnud laulavad ja päike paistab eredalt."),
    "eu" to listOf("Gaur eguraldi ederra dago.", "Parkean paseatu nahi nuke.", "Txoriak kantatzen ari dira eta eguzkiak distira egiten du."),
    "fa" to listOf("هوا امروز زیباست.", "می‌خواهم در پارک قدم بزنم.", "پرندگان آواز می‌خوانند و خورشید درخشان می‌درخشد."),
    "ga" to listOf("Tá an aimsir go hálainn inniu.", "Ba mhaith liom siúl sa pháirc.", "Tá na héin ag canann agus tá an ghrian ag taitneamh."),
    "gd" to listOf("Tha an aimsir brèagha an-diugh.", "Bu toil leum coiseachd anns a' phàirc.", "Tha na h-eòin a' seinn agus a' ghrian a' deàrrsadh."),
    "gu" to listOf("આજે હવામાન ખૂબ સુંદર છે.", "હું પાર્કમાં ચાલવા જવા માંગુ છું.", "પક્ષીઓ ગાઈ રહ્યા છે અને સૂર્ય તેજસ્વી રીતે ચમકે છે."),
    "he" to listOf("היום מזג האוויר יפהפה.", "הייתי רוצה לטייל בפארק.", "הציפורים שרות והשמש זורחת brightly."),
    "ht" to listOf("Tan an bèl jodi a.", "Mwen ta renmen mache nan pak la.", "Zwazo yo ap chante ak solèy la klere."),
    "hy" to listOf("Այսօր եղանակը գեղեdelays is delays beautiful.", "Ես կուզեի զբոսնել այգում:", "Թռdelays delays delays delays."),
    "is" to listOf("Veðrið er frábært í dag.", "Ég vil gjarnan ganga í garðinum.", "Fuglarnir syngja og sólin skín bjart."),
    "ka" to listOf("დღეს ამინდი ლამაზია.", "პარკში სეირნობა მინდა.", "ფრინველები მღერიან და მზე კაშკაშებს."),
    "kk" to listOf("Бүгін ауа-райы әдемі.", "Мен бақта серуендегім келеді.", "Құстар ән айтады және күн жарқырайды."),
    "kn" to listOf("ಇಂದು ಹವಾಮಾನ ಸುಂದರವಾಗಿದೆ.", "ನಾನು ಉದ್ಯಾನದಲ್ಲಿ ನಡೆಯಲು ಬಯಸುತ್ತೇನೆ.", "ಹಕ್ಕಿಗಳು ಹಾಡುತ್ತಿವೆ ಮತ್ತು ಸೂರ್ಯ ಪ್ರಕಾಶಮಾನವಾಗಿ ಹೊಳೆಯುತ್ತಿದ್ದಾನೆ."),
    "ku" to listOf("Hewa îro pir xweş e.", "Dixwazim di parkê de bigerim.", "Çûkî difînin û roj ronî dike."),
    "ky" to listOf("Бүгүн аба ырайы сулу.", "Мен бакта сейилдегим келет.", "Куштар ырдайт жана күн жаркырайт."),
    "la" to listOf("Hodie tempestas pulchra est.", "In ambulacrum ambulare vellem.", "Aves canunt et sol lucide lucet."),
    "lt" to listOf("Šiandien oras gražus.", "Noriu pasivaikščioti parke.", "Paukščiai dainuoja ir saulė ryškiai šviečia."),
    "lv" to listOf("Šodien laiks ir skaists.", "Es gribētu pastaigāties parkā.", "Putni dzied un saule spīd spoži."),
    "mk" to listOf("Денес времето е убаво.", "Сакам да прошетам во паркот.", "Птиците пеат и сонцето свети brightly."),
    "ml" to listOf("ഇന്ന് കാലാവസ്ഥ മനോഹരമാണ്.", "ഞാൻ പാർക്കിൽ നടക്കാൻ ആഗ്രഹിക്കുന്നു.", "പക്ഷികൾ പാടുന്നു, സൂര്യൻ തിളക്കത്തോടെ തിളങ്ങുന്നു."),
    "mr" to listOf("आज हवामान छान आहे.", "मला उद्यानात फिरायला जायचे आहे.", "पक्षी गात आहेत आणि सूर्य तेजस्वीपणे चमकत आहे."),
    "mt" to listOf("It-temp illum huwa sabiħ.", "Nixtieq nimxi fil-park.", "L-għasafar qed jkantaw u x-xemx qed tiddi b'mod brillanti."),
    "ne" to listOf("आज मौसम राम्रो छ।", "म पार्कमा हिँड्न चाहन्छु।", "चराहरू गाइरहेका छन् र घाम चम्किलो रूपमा चम्किरहेको छ।"),
    "om" to listOf("Haalli haala qillee gaarii qaba.", "Mana baadiyee keessa ba'uu nif barbaachisa.", "Shimbirrotonni fagoo fi aduu ifa ba'a."),
    "pa" to listOf("ਅੱਜ ਮੌਸਮ ਬਹੁਤ ਸੁੰਦਰ ਹੈ।", "ਮੈਂ ਪਾਰਕ ਵਿੱਚ ਸੈਰ ਕਰਨਾ ਚਾਹੁੰਦਾ ਹਾਂ।", "ਪੰਛੀ ਗਾ ਰਹੇ ਹਨ ਅਤੇ ਸੂਰਜ ਚਮਕਦਾਰ ਢੰਗ ਨਾਲ ਚਮਕ ਰਿਹਾ ਹੈ।"),
    "si" to listOf("අද කාලගුණය ලස්සනයි.", "මට උද්‍යානයේ ඇවිදීමට අවශ්‍යයි.", "පක්ෂීන් ගායනා කරනවා සහ හිරු දීප්තිමත්ව බබළනවා."),
    "sq" to listOf("Moti është i bukur sot.", "Do të doja të ecja në park.", "Zogjtë këndojnë dhe dielli shkëlqen ndritshëm."),
    "ta" to listOf("இன்று வானிலை அழகாக உள்ளது.", "நான் பூங்காவில் நடக்க விரும்புகிறேன்.", "பறவைகள் பாடுகின்றன, சூரியன் பிரகாசமாக ஒளிர்கிறது."),
    "te" to listOf("ఈరోజు వాతావరణం అందంగా ఉంది.", "నేను పార్కులో నడవాలని అనుకుంటున్నాను.", "పక్షులు పాడుతున్నాయి మరియు సూర్యుడు ప్రకాశవంతంగా ప్రకాశిస్తున్నాడు."),
    "ug" to listOf("بۈگۈن ھاۋا گۈزەل.", "باغچىدا سەيلە قىلغۇم بار.", "قۇشلار ناخشا ئېيتىدۇ ۋە قۇياش نۇر چاچىدۇ."),
    "ur" to listOf("آج موسم بہت خوبصورت ہے۔", "میں پارک میں سیر کرنا چاہتا ہوں۔", "پرندے گا رہے ہیں اور سورج چمکدار طور پر چمک رہا ہے۔"),
    "uz" to listOf("Bugun ob-havo juda chiroyli.", "Men bog'da sayr qilmoqchiman.", "Qushlar kuylaydi va quyosh yorqin porlaydi."),
    "yue" to listOf("今日天氣好好。", "我想去公園散步。", "雀仔唱歌，陽光明媚。"),
    "hak" to listOf("今日天氣做得好。", "想去公園行下。", "鳥仔在唱歌，日頭好光。"),
    "haw" to listOf("Nani ka lani i kēia lā.", "Makemake au e hele hele i ke kahua pāʻani.", "Nā manu e hula ana a me ka lā e kukui mālie ana."),
    "la" to listOf("Hodie tempestas pulchra est.", "In ambulacrum ambulare vellem.", "Aves canunt et sol lucide lucet."),
    "jbo" to listOf("le tcika cu xamgu je pluka", "mi djica lo nu cadzu ca lo nu klama lo sance", "le cipni cu pensi .i le solri cu glare"),
    "piqd" to listOf("HeghmoH chu' yIjatlh.", "DujvamDaq jIyIn.", "SuvwI'pu' yIghoS."),
    "qya" to listOf("I aurë anírë ná vanima.", "Merin auta i orto.", "Líri lendë ar anar cala alcarin."),
    "lfn" to listOf("La clima es escelente en la dia.", "Me vole pasia en la parca.", "La aselos canta e la sol brilia.")
)
