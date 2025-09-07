import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dianui/widgets/custom_app_bar.dart';
import '/../screens/settings/edit_profile_page.dart';
import 'dart:async';

class ChallengeCounterWidget extends StatefulWidget {
  final String challengeText;
  final String challengeIcon;
  final Color challengeColor;
  final DateTime startTime;
  final int challengeDurationDays;
  final VoidCallback onCancel;
  final VoidCallback onCompleted;

  const ChallengeCounterWidget({
    super.key,
    required this.challengeText,
    required this.challengeIcon,
    required this.challengeColor,
    required this.startTime,
    required this.challengeDurationDays,
    required this.onCancel,
    required this.onCompleted,
  });

  @override
  // ignore: library_private_types_in_public_api
  _ChallengeCounterWidgetState createState() => _ChallengeCounterWidgetState();
}

class _ChallengeCounterWidgetState extends State<ChallengeCounterWidget> {
  Duration _elapsed = Duration();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _elapsed = DateTime.now().difference(widget.startTime);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsed = DateTime.now().difference(widget.startTime);
      });
      if (_elapsed.inDays >= widget.challengeDurationDays) {
        timer.cancel();
        widget.onCompleted();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24).toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$days días $hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    double percent =
        (_elapsed.inSeconds / (widget.challengeDurationDays * 86400)).clamp(0, 1);

    return Container(
      margin: const EdgeInsets.only(bottom: 20.0),
      child: Card(
        // ignore: deprecated_member_use
        color: widget.challengeColor.withOpacity(0.15),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'Reto activo',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.challengeColor),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    widget.challengeIcon,
                    style: const TextStyle(fontSize: 48),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.challengeText,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: percent,
                backgroundColor: Colors.grey[300],
                color: widget.challengeColor,
                minHeight: 8,
              ),
              const SizedBox(height: 10),
              Text(
                'Tiempo transcurrido: ${_formatDuration(_elapsed)}',
                style: const TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: widget.onCancel,
                child: const Text(
                  'Cancelar reto',
                  style: TextStyle(color: Colors.red),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  Map<String, dynamic>? _activeChallenge;
  DateTime? _challengeStartTime;

  final int challengeDurationDays = 21;
  List<Map<String, dynamic>> _completedChallenges = [];


  List<String> _userFamilyRisks = [];
  final Map<String, String> _riskIcons = {
    'Diabetes': '💉',
    'Hipertensión': '🩺',
    'Obesidad': '⚖️',
    'Enfermedad cardíaca': '❤️',
    'Colesterol alto': '🧪',
    'Cáncer': '🎗️',
    'Osteoporosis': '🦴',
    'Enfermedad renal': '🩸',
    'Accidente cerebrovascular': '🧠',
    'Enfermedad hepática': '🫁',
    'Depresión': '😔',
    'Alzheimer': '🧠',
    'Artritis': '🦴',
    'Ninguno': '✅',
  };

  // Lista de retos predefinidos
  final List<Map<String, dynamic>> retos = [
    {"icon": "🍫", "color": Colors.brown, "texto": "Dejar el chocolate"},
    {"icon": "🍭", "color": Colors.cyanAccent, "texto": "Dejar el azúcar"},
    {"icon": "🍬", "color": Colors.redAccent, "texto": "Dejar los dulces"},
    {"icon": "🍔", "color": Colors.green, "texto": "Dejar la comida rápida"},
    {"icon": "☕", "color": Colors.greenAccent, "texto": "Dejar el café"},
    {"icon": "🍺", "color": Colors.orangeAccent, "texto": "Dejar el alcohol"},
    {"icon": "🍕", "color": Colors.yellowAccent, "texto": "Dejar la pizza"},
    {"icon": "🥩", "color": Colors.red, "texto": "Dejar la carne"},
    {"icon": "🚬", "color": Colors.blueGrey, "texto": "Dejar el cigarro"},
    {"icon": "➕", "color": Colors.white70, "texto": "Agregar reto"}
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  bool _isChallengeCompleted(String texto) {
    return _completedChallenges.any((c) => c['text'] == texto);
  }

  Future<void> _loadUserData() async {
  if (user == null) {
    setState(() => _isLoading = false);
    return;
  }

  try {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    if (userDoc.exists) {
      final data = userDoc.data() as Map<String, dynamic>;

      // 🔹 CARGAR RIESGOS FAMILIARES DESDE SUBCOLECCIÓN (FUERA DE setState)
      final QuerySnapshot riesgosSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('riesgos_familiares')
          .orderBy('orden')
          .get();

      final List<String> riesgosFromFirestore = riesgosSnapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['riesgo'] as String)
          .toList();

      // Determinar qué riesgos usar (subcolección o array legacy)
      final List<String> finalFamilyRisks = riesgosFromFirestore.isNotEmpty
          ? riesgosFromFirestore
          : (data.containsKey('familyRisks')
              ? List<String>.from(data['familyRisks'])
              : []);

      setState(() {
        _userData = data;
        _isLoading = false;

        if (data.containsKey('completedChallenges')) {
          final List<dynamic> completadosRaw = data['completedChallenges'];
          _completedChallenges = completadosRaw.map((item) {
            return {
              'text': item['text'],
              'icon': item['icon'],
              'color': Color(item['color']), // Convertir int a Color
            };
          }).toList();
        }

        // Verificar si hay un reto activo guardado
        if (data.containsKey('activeChallenge') && data.containsKey('challengeStartTime')) {
          final Map<String, dynamic> retoData = data['activeChallenge'];
          final Timestamp ts = data['challengeStartTime'];

          _activeChallenge = {
            'texto': retoData['texto'],
            'icon': retoData['icon'],
            'color': Color(retoData['color']), // Convertir int a Color
          };

          _challengeStartTime = ts.toDate();
        }

        // 🔹 ASIGNAR RIESGOS FAMILIARES (YA CALCULADOS ARRIBA)
        _userFamilyRisks = finalFamilyRisks;
      });
    } else {
      setState(() => _isLoading = false);
    }
  } catch (e) {
    if (kDebugMode) {
      print("Error al cargar datos del usuario: $e");
    }
    setState(() => _isLoading = false);
  }
}


  void _startChallenge(Map<String, dynamic> reto) async {
    if (_activeChallenge != null && _challengeStartTime != null) {
      // Ya hay un reto activo
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya hay un reto activo. Debes cancelarlo antes de iniciar otro'),
          backgroundColor: Colors.orange,
          )
      );
      return;
    }

  setState(() {
    _activeChallenge = reto;
    _challengeStartTime = DateTime.now();
  });

  if (user != null) {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .update({
      'activeChallenge': {
        'texto': reto['texto'],
        'icon': reto['icon'],
        'color': reto['color'].value, // Guardamos el valor entero del color
      },
      'challengeStartTime': Timestamp.fromDate(_challengeStartTime!),
    });
  }
}

  void _cancelChallenge() async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar reto'),
        content: const Text('¿Estás seguro de que quieres cancelar el reto actual?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No')
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Sí, cancelar',
              style: TextStyle(color: Colors.red),
            )
          )
        ],
      ),
    );

    if (shouldCancel == true) {
      setState(() {
      _activeChallenge = null;
      _challengeStartTime = null;
      });

      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .update({
          'activeChallenge': FieldValue.delete(),
          'challengeStartTime': FieldValue.delete(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reto cancelado'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _completeChallenge() async {
    if (_activeChallenge  == null || _challengeStartTime == null) return;

    final challengeRecord = {
      'text': _activeChallenge!['texto'],
      'icon': _activeChallenge!['icon'],
      'color': (_activeChallenge!['color'] as Color).toARGB32(),
      'startTime': _challengeStartTime,
      'endTime': DateTime.now(),
    };

    // Guardar en Firestore
    if (user != null) {
      await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .update({
          'completedChallenges': FieldValue.arrayUnion([challengeRecord]),
          'activeChallenge': FieldValue.delete(),
          'challengeStartTime': FieldValue.delete(),
        });
    }

    // Mostrar recompensas
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¡Felicidades! 🎉'),
        content: const Text('Completaste tu reto de 21 días.\n¡Sigue así?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
            )
        ],
      )
    );

    // Limpiar el estado local
    setState(() {
      _activeChallenge = null;
      _challengeStartTime = null;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Perfil"),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userData == null
              ? const Center(
                  child: Text(
                    "No se pudo cargar la información del usuario",
                    style: TextStyle(color: Colors.red),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: _buildProfileContent(),
                  ),
                ),
    );
  }

  Widget _buildProfileContent() {
    final String userName = _userData!['name'] ?? 'Usuario';
    final String userEmail = user?.email ?? 'correo@provedor.com';
    final String profileImage =
        _userData!['profileImage'] ?? 'assets/images/icon_pfp.png';
    final String userAge = _userData!["age"]?.toString() ?? "N/A";
    final String userPhone = _userData!["phone"] ?? "N/A";
    final String userCity = _userData!["city"] ?? "Ciudad desconocida";
    final String userOccupation = _userData!["occupation"] ?? "Ocupación no registrada";

    String userRole = 'Usuario';
    if (_userData!.containsKey('nutritionist')) {
      final dynamic roleData = _userData!['nutritionist'];
      if (roleData is bool) {
        userRole = roleData ? 'Nutriólogo' : 'Usuario';
      } else if (roleData is String) {
        userRole = (roleData.toLowerCase() == 'true') ? 'Nutriólogo' : 'Usuario';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: profileImage.startsWith('http')
                  ? NetworkImage(profileImage)
                  : AssetImage(profileImage) as ImageProvider,
              backgroundColor: Colors.grey[200],
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text('Edad: $userAge', style: const TextStyle(fontSize: 14)),
                Text('Vegetariano', style: const TextStyle(fontSize: 16)),
                Text(
                  userRole,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: (userRole == "Nutriólogo") ? Colors.green : Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 30),
        Row(
          children: [
            const Text(
              'Mis datos',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EditProfilePage()),
                );
              },
              child: const Text(
                'Editar',
                style: TextStyle(fontSize: 18, color: Colors.blue),
              ),
            ),
          ],
        ),
        _buildInfoRow(Icons.mail, userEmail),
        _buildInfoRow(Icons.phone, userPhone),
        _buildInfoRow(Icons.location_on, userCity),
        _buildInfoRow(Icons.work, userOccupation),
        const SizedBox(height: 15),
        const Text(
          "Riesgos familiares",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        // 🔹 FILTRAR Y MOSTRAR LOS RIESGOS DEL USUARIO
        ..._userFamilyRisks.map((risk) {
          final emoji = _riskIcons[risk] ?? '❓'; // Emoji por defecto si no se encuentra
          return _buildEmojiRow(emoji, risk);
        }).toList(),
        const SizedBox(height: 20),
        if (_activeChallenge != null && _challengeStartTime != null)
          ChallengeCounterWidget(
            challengeText: _activeChallenge!['texto'],
            challengeIcon: _activeChallenge!['icon'],
            challengeColor: _activeChallenge!['color'],
            startTime: _challengeStartTime!,
            challengeDurationDays: challengeDurationDays,
            onCancel: _cancelChallenge,
            onCompleted: _completeChallenge,
          ),
        const Text(
          'Retos',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: retos.map((reto) {
              final bool completado = _isChallengeCompleted(reto['texto']);

              return Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      _startChallenge(reto);
                    },
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Card(
                          color: reto['color'],
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 3,
                          child: SizedBox(
                            width: 120,
                            height: 100,
                            child: Center(
                              child: Text(
                                reto['icon'],
                                style: const TextStyle(fontSize: 40),
                              ),
                            ),
                          ),
                        ),
                        if (completado)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Icon(Icons.emoji_events, color: Colors.amber[700], size: 24),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    reto['texto'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          const SizedBox(width: 5),
          Icon(icon, size: 24),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontSize: 20)),
        ],
      ),
    );
  }

  Widget _buildEmojiRow(String emoji, String text) {
    return Row(
      children: [
        const SizedBox(width: 5),
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(fontSize: 20)),
      ],
    );
  }
}
