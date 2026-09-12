
class FatwaRuling {
  final String question;
  final String questionAr;
  final String answer;
  final String answerAr;
  final String scholar;
  final String source;
  final String category;
  final String categoryAr;
  const FatwaRuling({required this.question, required this.questionAr, required this.answer, required this.answerAr, required this.scholar, required this.source, required this.category, required this.categoryAr});
}

class FatwaService {
  static const List<FatwaRuling> _rulings = [
    FatwaRuling(category: 'Prayer', categoryAr: 'الصلاة', question: 'Can a traveler shorten (Qasr) their prayers?', questionAr: 'هل يجوز للمسافر أن يقصر صلاته؟', answer: 'Yes. It is an established Sunnah for a traveler undertaking a journey of a recognized distance to shorten the 4-rakah prayers to 2 rakahs each.', answerAr: 'نعم، يجوز ذلك وهو سنة ثابتة. فالمسافر مسافة سفر معتبرة شرعًا يقصر الصلاة الرباعية فيجعلها ركعتين.', scholar: 'General consensus', source: 'Mainstream Fiqh reference'),
    FatwaRuling(category: 'Prayer', categoryAr: 'الصلاة', question: 'Can a traveler combine two prayers (Jam)?', questionAr: 'هل يجوز للمسافر أن يجمع بين صلاتين؟', answer: 'Yes. Combining Dhuhr with Asr, and Maghrib with Isha, is permitted while traveling for ease during the journey.', answerAr: 'نعم، يجوز جمع الظهر مع العصر، والمغرب مع العشاء، تخفيفًا على المسافر أثناء سفره.', scholar: 'General consensus', source: 'Mainstream Fiqh reference'),
    FatwaRuling(category: 'Prayer', categoryAr: 'الصلاة', question: 'I woke up after a prayer time had passed. What should I do?', questionAr: 'استيقظت بعد خروج وقت الصلاة، فماذا أفعل؟', answer: 'Pray it as soon as you wake up or remember -- there is no sin for an unintentional delay caused by sleep or forgetfulness.', answerAr: 'صلّها فور استيقاظك أو تذكّرك، فلا إثم عليك في تأخير غير مقصود بسبب النوم أو النسيان.', scholar: 'General consensus', source: 'Mainstream Fiqh reference'),
    FatwaRuling(category: 'Fasting', categoryAr: 'الصيام', question: 'I ate or drank by mistake while fasting -- is my fast broken?', questionAr: 'أكلت أو شربت ناسيًا وأنا صائم، فهل يفسد صيامي؟', answer: 'No, according to the majority view. If you genuinely forgot, your fast remains valid; stop as soon as you remember.', answerAr: 'لا يفسد صيامك عند جمهور العلماء، فمن أكل أو شرب ناسيًا فليتم صومه، فإنما أطعمه الله وسقاه.', scholar: 'Majority view', source: 'Mainstream Fiqh reference'),
    FatwaRuling(category: 'Zakat', categoryAr: 'الزكاة', question: 'Is Zakat due on wealth that has not reached the Nisab threshold?', questionAr: 'هل تجب الزكاة في مال لم يبلغ النصاب؟', answer: 'No. Zakat only becomes obligatory once your zakatable wealth reaches the Nisab AND remains so for a full lunar year (Hawl).', answerAr: 'لا تجب الزكاة إلا إذا بلغ المال النصاب المقرر شرعًا، وحال عليه الحول الهجري كاملًا.', scholar: 'General consensus', source: 'Mainstream Fiqh reference'),
    FatwaRuling(category: 'Purification', categoryAr: 'الطهارة', question: 'What are the most commonly agreed things that break Wudu?', questionAr: 'ما أشهر نواقض الوضوء المتفق عليها؟', answer: 'Using the toilet, passing wind, deep sleep, and the flow of blood or impurities from the body. Some details differ between schools.', answerAr: 'قضاء الحاجة، وخروج الريح، والنوم العميق المستغرق، وخروج الدم أو النجاسات من الجسد، مع خلاف في بعض التفاصيل بين المذاهب.', scholar: 'Cross-madhhab summary', source: 'Mainstream Fiqh reference'),
    FatwaRuling(category: 'Zakat', categoryAr: 'الزكاة', question: 'Is Zakat due on jewelry a woman wears regularly?', questionAr: 'هل تجب الزكاة في الذهب الذي تلبسه المرأة باستمرار؟', answer: 'A matter of scholarly difference: some hold no zakat is due on jewelry for personal use, others hold it is due if it reaches nisab. Consult a trusted scholar.', answerAr: 'من مسائل الخلاف الفقهي؛ ذهب كثير من العلماء لعدم وجوب الزكاة في الحلي للاستعمال الشخصي، وأوجبها آخرون إذا بلغ النصاب.', scholar: 'Scholarly difference', source: 'Mainstream Fiqh reference'),
    FatwaRuling(category: 'Fasting', categoryAr: 'الصيام', question: 'Does forgetting and eating break the fast?', questionAr: 'هل النسيان والأكل أثناء الصيام يفطر الصائم؟', answer: 'No. If a fasting person eats or drinks forgetfully, their fast remains valid.', answerAr: 'لا يفطر. من أكل أو شرب ناسيًا وهو صائم فصومه صحيح، لقول النبي صلى الله عليه وسلم: فإنما أطعمه الله وسقاه.', scholar: 'General consensus', source: 'Mainstream Fiqh reference'),
    FatwaRuling(category: 'Fasting', categoryAr: 'الصيام', question: 'Can a sick or traveling person break their fast?', questionAr: 'هل يجوز للمريض أو المسافر الفطر في رمضان؟', answer: 'Yes, with the missed days made up later.', answerAr: 'نعم، رخّص القرآن في ذلك صراحة، مع وجوب القضاء بعد زوال العذر.', scholar: 'General consensus', source: 'Quran, Al-Baqarah 2:184-185'),
    FatwaRuling(category: 'Purification', categoryAr: 'الطهارة', question: 'Does touching a woman break wudu?', questionAr: 'هل لمس المرأة ينقض الوضوء؟', answer: 'A matter of scholarly difference between the Fiqh schools.', answerAr: 'من مسائل الخلاف المعتبر بين المذاهب الفقهية؛ فبعضهم يرى عدم النقض وبعضهم يرى النقض بشروط.', scholar: 'Scholarly difference', source: 'Mainstream Fiqh reference'),
    FatwaRuling(category: 'Marriage', categoryAr: 'الزواج والأسرة', question: 'Is a marriage valid without a dowry specified?', questionAr: 'هل يصح عقد الزواج بدون تحديد مهر؟', answer: 'Yes, though specifying it is recommended; the wife is then entitled to Mahr al-Mithl.', answerAr: 'يصح العقد ولو لم يُحدَّد المهر، وللزوجة حينها مهر المثل.', scholar: 'General consensus', source: 'Mainstream Fiqh reference'),
    FatwaRuling(category: 'Business', categoryAr: 'المعاملات', question: 'Is an interest-based loan permitted out of necessity?', questionAr: 'هل يجوز الاقتراض بالربا عند الضرورة القصوى؟', answer: 'Only under genuine, life-threatening necessity with no lawful alternative -- not ordinary hardship.', answerAr: 'لا يُباح الربا إلا في ضرورة قصوى لا بديل مشروع عنها، وليس لمجرد ضيق مالي عادي.', scholar: 'General consensus', source: 'Quran, Al-Baqarah 2:275'),
    FatwaRuling(category: 'Hajj', categoryAr: 'الحج', question: 'Is Hajj obligatory on someone who cannot afford it?', questionAr: 'هل يجب الحج على من لا يستطيع تكاليفه؟', answer: 'No, only on those with financial and physical capability.', answerAr: 'لا يجب الحج إلا على المستطيع ماليًا وبدنيًا.', scholar: 'General consensus', source: 'Quran, Aal-E-Imran 3:97'),
    FatwaRuling(category: 'Prayer', categoryAr: 'الصلاة', question: 'Can a woman pray in the mosque congregation?', questionAr: 'هل يجوز للمرأة أن تصلي في جماعة المسجد؟', answer: 'Yes, permissible and practiced at the time of the Prophet, peace be upon him.', answerAr: 'نعم يجوز، وقد كان معروفًا في عهد النبي صلى الله عليه وسلم.', scholar: 'General consensus', source: 'Hadith, Sahih Muslim'),
  ];

  static Future<List<FatwaRuling>> getFatwaByCategory(String category) async {
    if (category.isEmpty || category == 'All') return _rulings;
    return _rulings.where((r) => r.category == category).toList();
  }

  static Future<List<FatwaRuling>> getAll() async => _rulings;
  static List<String> get categories => _rulings.map((r) => r.category).toSet().toList()..sort();
}
