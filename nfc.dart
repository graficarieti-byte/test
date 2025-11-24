import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
// import 'package:ndef/ndef.dart' as ndef; 


class LetturaNfc extends StatefulWidget {
  const LetturaNfc({super.key});

  @override
  State<LetturaNfc> createState() {
    return _LetturaNfc();
  }

}

class _LetturaNfc extends State<LetturaNfc> {

late Future<void> Function() functionScan;


/// Converte la stringa UID letta dal tag (es. "A1B2C3D4E5F61122"
/// o "A1 B2 C3 D4 E5 F6 11 22") in una lista di 8 byte
/// in ordine LSB → MSB (come richiesto da ISO15693).
List<int> uidByte(String uid) {
  // 1) tolgo spazi ed eventuali separatori
  final cleaned = uid.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '');

  // 2) controllo che la lunghezza sia multipla di 2
  if (cleaned.length % 2 != 0) {
    throw FormatException('UID in formato esadecimale non valido: $uid');
  }

  // 3) creo la lista di byte [0xA1, 0xB2, ...]
  final bytes = <int>[];
  for (var i = 0; i < cleaned.length; i += 2) {
    final byteString = cleaned.substring(i, i + 2);
    final value = int.parse(byteString, radix: 16);
    bytes.add(value);
  }

  // 4) ISO15693 vuole l’UID in ordine invertito
  return bytes.reversed.toList(); //bytes.reversed.toList()
}

String bytesToHex(List<int> bytes) {
  return bytes
      .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
      .join(' ');
  }


@override
 void initState() {
    super.initState();
    functionScan = _leggiNFC;  // Ora l’istanza esiste
  }


  List<Map<String, String>> _summaryData = [];

  Widget messaggioLoad = const SizedBox.shrink();
  String txtButton = 'Scansiona';
  String messaggioerrore = '';

 
 Future<void> annullaFct() async{
        await FlutterNfcKit.finish();
        setState(() {
           txtButton = 'Scansiona';
            functionScan = _leggiNFC;
            messaggioLoad = const SizedBox.shrink();
            _summaryData = [];
        });
        
      }
  

  Future<void> _leggiNFC() async {
    try {
      setState(() {
        messaggioLoad = Image.asset('assets/images/Loading_icon.gif', width: 50,);
        txtButton = 'Annulla';
        functionScan = annullaFct;
      });

      final datiNfc = await FlutterNfcKit.poll();

      //const idFake = '02189078665102E0';
//--
    final uidReversed = uidByte(datiNfc.id);
   if (uidReversed.length != 8) {
      throw Exception('\n UID non è di 8 byte, trovato: ${uidReversed.length}');
    }

  

    // 3) costruisco il frame ISO15693: READ SINGLE BLOCK
    //
    // Flags:        0x22  (addressed + high data rate, esempio tipico)
    // Command:      0x20  (Read Single Block)
    // UID (8 byte): uidReversed
    // Block number: 0x05  (voglio leggere blocco 5)
   const int blockNumber = 0x05; ///

   final Uint8List frame = Uint8List.fromList([
      0x22,          // Flags
      0x20,          // Command code: Read Single Block
      0xE0, 0x02, 0x51, 0x66, 0x78, 0x90, 0x18, 0x02, // UID in ordine LSB → MSB
      blockNumber,   // Block address
    ]);


 /*List<Map<String,String>> summary = [
        {
          'check': 'Tag rilevato',
          'type': 'Type: ${datiNfc.type}',
          'ID': 'ID: ${datiNfc.id}',
          'Standard': 'Standard: ${datiNfc.standard}',
          'ATQA': 'ATQA: ${datiNfc.atqa}',
          'SAK': 'SAK: ${datiNfc.sak}',
          'Historical_bytes': 'Historical_bytes ${datiNfc.historicalBytes}',
          'protocollo': 'Protocollo: ${datiNfc.protocolInfo}',
          'App_data': 'App data: ${datiNfc.applicationData}',
          'hash_code': 'Hash code:${datiNfc.hashCode}',
          'data_hex': 'Dati letti: ${dataHex}',
      }

      ];*/
     setState(() {
        messaggioLoad = const SizedBox.shrink();
        functionScan = _leggiNFC;
        txtButton = 'Reset';
      });

    final Uint8List response = await FlutterNfcKit.transceive(frame);

    if (response.isEmpty) {
      throw Exception('Risposta vuota dal tag.');
    }

    final int respFlags = response[0];
    final List<int> dataBytes = response.sublist(1);

     // 5) controllo il flag di risposta
    if (respFlags != 0x00) {
      // 0x00 = successo secondo ISO15693
      throw Exception('Errore ISO15693, flag risposta: 0x${respFlags.toRadixString(16)}');
    }


    // 6) converto i dati letti in esadecimale, es. "DE AD BE EF"
    final dataHex = bytesToHex(dataBytes); 

     List<Map<String,String>> summary = [
        {
          'check': 'Tag rilevato',
          'type': 'Type: ${datiNfc.type}',
          'ID': 'ID: ${datiNfc.id} codificato final uidReversed = uidByte(datiNfc.id);',
          'Standard': 'Standard: ${datiNfc.standard}',
          'ATQA': 'ATQA: ${datiNfc.atqa}',
          'SAK': 'SAK: ${datiNfc.sak}',
          'Historical_bytes': 'Historical_bytes ${datiNfc.historicalBytes}',
          'protocollo': 'Protocollo: ${datiNfc.protocolInfo}',
          'App_data': 'App data: ${datiNfc.applicationData}',
          'hash_code': 'Hash code:${datiNfc.hashCode}',
          'data_hex': 'Dati letti: $dataHex',
      }

      ];


      setState(() {
        messaggioLoad = const SizedBox.shrink();
        //summary = [{'data_hex' : dataHex}];
        _summaryData = summary;
        txtButton = 'Reset';
        functionScan = _leggiNFC;
      });

      

      await FlutterNfcKit.finish();

    } catch (e) {

        final datiNfc = await FlutterNfcKit.poll();
        final uidReversed = bytesToHex(uidByte(datiNfc.id));
        List<Map<String,String>> summary = [
        {
          'check': 'Errore nella lettura NFC:\n"$e"',
          'type': 'Type: ${datiNfc.type}',
          'ID': 'ID: ${datiNfc.id} codificato $uidReversed}',
          'Standard': 'Standard: ${datiNfc.standard}',
          'ATQA': 'ATQA: ${datiNfc.atqa}',
          'SAK': 'SAK: ${datiNfc.sak}',
          'Historical_bytes': 'Historical_bytes ${datiNfc.historicalBytes}',
          'protocollo': 'Protocollo: ${datiNfc.protocolInfo}',
          'App_data': 'App data: ${datiNfc.applicationData}',
          'hash_code': 'Hash code:${datiNfc.hashCode}',
          
      }

      ];

      setState(() {
        _summaryData = summary;
        messaggioLoad = const SizedBox.shrink();
        txtButton = 'Reset';
      });
      await FlutterNfcKit.finish();
    } 

  }

  
 @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(50),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children:[ 
      
            SizedBox(
              height: 300,
              width: double.infinity,
             child: 
                SingleChildScrollView(
                  child: Row( 
                    mainAxisAlignment: MainAxisAlignment.center,
                    //crossAxisAlignment: CrossAxisAlignment.start,
                    children: 
                           _summaryData.map((data){
                                            return 
                                            Expanded( //manda a capo in automatico elementi che vanno fuori
                                              child: Column(
                                               crossAxisAlignment: CrossAxisAlignment.start,
                                               //mainAxisAlignment: MainAxisAlignment.start,
                                               //mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text('${data['check']}'),
                                                    // Text((data['type'] as String)),
                                                    Text('${data['ID']}'),
                                                    Text('${data['Standard']}'),
                                                    //Text((data['ATQA'] as String)),
                                                    //Text((data['SAK'] as String)),
                                                    //Text((data['Historical_bytes'] as String)),
                                                    //Text((data['protocollo'] as String)),
                                                    //Text((data['App_data'] as String)),
                                                    //Text((data['hash_code'] as String)),
                                                    Text('${data['data_hex']}'),
                                                    Text(messaggioerrore),
                                                  ],
                                                ),
                                            )
                                            ;}).toList(),
                          ),
                        ),
                      ),
          //TextButton(onPressed: _leggiNFC, child: Text('Scansiona')),   
          messaggioLoad,
          SizedBox(height: 40,),
          ElevatedButton(
              onPressed: functionScan,
              style: ElevatedButton.styleFrom(
                shape: CircleBorder(),
                padding: EdgeInsets.all(40),
                ),
              child:
              Text(txtButton)),
          ]),
    );
  }

}
  }

}
