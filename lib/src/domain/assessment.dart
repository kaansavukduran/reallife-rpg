class KnowledgeQuestion {
  const KnowledgeQuestion(
    this.prompt,
    this.options,
    this.answer,
    this.explanation,
  );
  final String prompt, explanation;
  final List<String> options;
  final int answer;
}

class SkillSpec {
  const SkillSpec(
    this.id,
    this.name,
    this.description,
    this.challenge,
    this.questions,
  );
  final String id, name, description, challenge;
  final List<KnowledgeQuestion> questions;
  int grade(List<int?> answers) {
    if (answers.length != questions.length || answers.any((a) => a == null)) {
      throw const FormatException('Her soruyu yanıtla');
    }
    var correct = 0;
    for (var i = 0; i < questions.length; i++) {
      final a = answers[i]!;
      if (a < 0 || a >= questions[i].options.length) {
        throw const FormatException('Geçersiz seçenek');
      }
      if (a == questions[i].answer) correct++;
    }
    return correct;
  }
}

/// Small, versioned screening samples, not proficiency certificates.
const skillCatalog = [
  SkillSpec(
    'software',
    'Yazılım geliştirme',
    'Mantık, veri yapıları ve güvenilir yazılım.',
    'Bir görev listesindeki günlük tekrarları yöneten bir algoritma tasarla. Görevin başlangıç tarihini, hafta içi tekrarını ve sonradan işaretlenen günleri ele al. Sözde kod, en az üç sınır durumu testi, zaman karmaşıklığı ve bir tasarım ödünleşimi yaz.',
    [
      KnowledgeQuestion(
        'Sıralı bir dizide ikili aramanın zaman karmaşıklığı nedir?',
        ['O(n²)', 'O(log n)', 'O(n)', 'O(1)'],
        1,
        'Her adımda arama alanı yarıya iner: O(log n).',
      ),
      KnowledgeQuestion(
        'Aynı isteğin tekrar işlenmesi tek bir sonuç üretmeli. Hangi özellik gerekir?',
        ['Kalıtım', 'Özyineleme', 'İdempotans', 'Sıkıştırma'],
        2,
        'İdempotans, yeniden denemelerin ek yan etki üretmesini önler.',
      ),
      KnowledgeQuestion(
        'Parolalar sunucuda nasıl tutulmalı?',
        [
          'Düz metin',
          'Geri çözülebilir şifreleme',
          'Base64',
          'Tuzlanmış Argon2id gibi parola özeti',
        ],
        3,
        'Parola için yavaş, tuzlanmış bir parola özetleme algoritması gerekir.',
      ),
      KnowledgeQuestion(
        'Bir işlem borç ve alacak kayıtlarını birlikte yazmalı. Ne kullanılır?',
        [
          'Atomik veritabanı işlemi',
          'Yalnız önbellek',
          'İki bağımsız yazma',
          'Daha uzun zaman aşımı',
        ],
        0,
        'Atomik işlem iki kaydın da yazılmasını veya ikisinin de geri alınmasını sağlar.',
      ),
      KnowledgeQuestion(
        'Boş bir liste ve artık yıl tarihi için test yazmak neyi kontrol eder?',
        [
          'Yalnız performans',
          'Sınır durumları',
          'Görsel stil',
          'Ağ bant genişliği',
        ],
        1,
        'Sınır durumları normal örneklerin yakalayamadığı hataları bulur.',
      ),
    ],
  ),
  SkillSpec(
    'english',
    'İngilizce',
    'Anlama, dil bilgisi ve yazılı anlatım.',
    'Write a 150–250 word email proposing a weekly learning group. Explain its goal, a realistic schedule, how progress will be measured, and how you would accommodate someone with limited time. Use your own words.',
    [
      KnowledgeQuestion(
        'Choose the correct sentence.',
        [
          'She have lived here since 2020.',
          'She lives here since 2020.',
          'She has lived here since 2020.',
          'She living here since 2020.',
        ],
        2,
        'Present perfect with since connects a past starting point to the present.',
      ),
      KnowledgeQuestion(
        '“Despite the rain, they continued.” What happened?',
        [
          'They stopped because of rain.',
          'They continued although it rained.',
          'It never rained.',
          'They waited for sunshine.',
        ],
        1,
        'Despite introduces a contrast: rain did not stop them.',
      ),
      KnowledgeQuestion(
        'Complete: If I had more time, I ___ a new language.',
        ['will learn', 'learned', 'would learn', 'have learned'],
        2,
        'Second conditional uses if + past simple and would + infinitive.',
      ),
      KnowledgeQuestion(
        'Which is the most appropriate formal request?',
        [
          'Give me that now.',
          'You must send it.',
          'Send!',
          'Could you please send the report?',
        ],
        3,
        'Could you please is a polite, conventional request.',
      ),
      KnowledgeQuestion(
        'What does “reliable evidence” mean?',
        ['Güvenilir kanıt', 'Hızlı karar', 'Eski alışkanlık', 'Kişisel tercih'],
        0,
        'Reliable means trustworthy; evidence means supporting information.',
      ),
    ],
  ),
  SkillSpec(
    'research',
    'Araştırma okuryazarlığı',
    'Kanıtı sorgula, yöntemleri karşılaştır.',
    '“Günde 20 dakika yürüyüş odaklanmayı artırır” iddiasını değerlendirecek bir çalışma tasarla. Hipotez, kontrol grubu, karıştırıcı değişkenler, ölçüm yöntemi, örneklem sınırlılıkları ve hangi sonuçların iddiayı desteklemeyeceğini açıkla.',
    [
      KnowledgeQuestion(
        'Korelasyon için hangi ifade doğrudur?',
        [
          'Her zaman nedenselliktir.',
          'İki değişken birlikte değişebilir; neden kanıtlanmaz.',
          'Deneye gerek bırakmaz.',
          'Örneklemden bağımsızdır.',
        ],
        1,
        'Ortak bir neden veya ters nedensellik ilişkiyi açıklayabilir.',
      ),
      KnowledgeQuestion(
        'Rastgele atamanın temel amacı nedir?',
        [
          'Sonucu garantilemek',
          'Örneklemi küçültmek',
          'Gruplar arasındaki sistematik farkları azaltmak',
          'Her veriyi aynı yapmak',
        ],
        2,
        'Rastgele atama karıştırıcı değişkenleri ortalamada dengelemeye yardım eder.',
      ),
      KnowledgeQuestion(
        'Bir iddiayı sınamak için en yararlı yaklaşım?',
        [
          'Yalnız destekleyen örnekleri seçmek',
          'En popüler gönderiye bakmak',
          'Kaynağın unvanına güvenmek',
          'İddiayı yanlışlayabilecek kanıtları da aramak',
        ],
        3,
        'Yanlışlama olasılığını araştırmak doğrulama yanlılığını azaltır.',
      ),
      KnowledgeQuestion(
        'Küçük bir örneklemin önemli sınırlılığı nedir?',
        [
          'Belirsizlik ve genelleme güçlüğü',
          'Kesinlikle yanlış olması',
          'Verinin sayısal olmaması',
          'Etik kurala ihtiyaç olmaması',
        ],
        0,
        'Küçük örneklemler daha geniş belirsizlik ve sınırlı temsil doğurabilir.',
      ),
      KnowledgeQuestion(
        'Tekrarlanabilir bir çalışma ne sunmalıdır?',
        [
          'Yalnız sonuç başlığı',
          'Yöntem, veri koşulları ve analiz adımları',
          'Yalnız araştırmacı adı',
          'Yalnız olumlu sonuçlar',
        ],
        1,
        'Yöntem ve analiz şeffaflığı başka araştırmacıların kontrolünü sağlar.',
      ),
    ],
  ),
];
