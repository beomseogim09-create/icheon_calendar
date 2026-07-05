import 'package:flutter/material.dart';
import 'dart:convert'; // 데이터를 변환하기 위해 필요함
import 'package:shared_preferences/shared_preferences.dart'; // 데이터 저장소 패키지라고함

// 4번 담당자(메모 기능 - 영구 저장) 코드

// 1. 데이터 모델 및 JSON 변환 로직
class Memo {
  String title;
  String content;
  Memo({required this.title, required this.content});

  // 메모를 저장하기 위해 JSON 형태로 변환
  Map<String, dynamic> toJson() => {
        'title': title,
        'content': content,
      };

  // 저장된 JSON에서 다시 메모로 복구
  factory Memo.fromJson(Map<String, dynamic> json) => Memo(
        title: json['title'],
        content: json['content'],
      );
}

class Folder {
  String name;
  List<Memo> memos;
  Folder({required this.name, required this.memos});

  // 폴더와 그 안의 메모들을 JSON 형태로 변환
  Map<String, dynamic> toJson() => {
        'name': name,
        'memos': memos.map((m) => m.toJson()).toList(),
      };

  // 저장된 JSON에서 다시 폴더로 복구
  factory Folder.fromJson(Map<String, dynamic> json) => Folder(
        name: json['name'],
        memos: (json['memos'] as List).map((m) => Memo.fromJson(m)).toList(),
      );
}

// 전역 변수로 폴더 리스트 관리
List<Folder> myFolders = [];

// 스마트폰 저장소에 현재 데이터를 통째로 덮어쓰는 함수
Future<void> saveFoldersData() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String> folderStrings =
      myFolders.map((f) => jsonEncode(f.toJson())).toList();
  await prefs.setStringList('saved_folders', folderStrings);
}

// 2. 폴더 목록 화면
class MemoFolderScreen extends StatefulWidget {
  const MemoFolderScreen({super.key});

  @override
  State<MemoFolderScreen> createState() => _MemoFolderScreenState();
}

class _MemoFolderScreenState extends State<MemoFolderScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFoldersData(); // 화면이 켜질 때 저장된 데이터 불러오기
  }

  // 스마트폰 저장소에서 데이터를 읽어오는 함수
  Future<void> _loadFoldersData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? folderStrings = prefs.getStringList('saved_folders');

    if (folderStrings != null) {
      myFolders =
          folderStrings.map((s) => Folder.fromJson(jsonDecode(s))).toList();
    }

    setState(() {
      _isLoading = false; // 로딩 끝!
    });
  }

  void _showAddFolderDialog() {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("새 폴더 만들기"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "폴더 이름을 입력하세요"),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("취소"),
            ),
            TextButton(
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    myFolders.add(Folder(name: controller.text, memos: []));
                  });
                  await saveFoldersData(); // 폴더를 만들었으니 저장!
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text("만들기"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("메모 폴더"),
      ),
      // 로딩 중이면 뱅글뱅글 아이콘 표시
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : myFolders.isEmpty
              ? const Center(child: Text("우측 하단 + 버튼을 눌러 폴더를 추가해보세요!"))
              : ListView.builder(
                  itemCount: myFolders.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.folder, color: Colors.indigo),
                        title: Text(myFolders[index].name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("메모 ${myFolders[index].memos.length}개"),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  MemoListScreen(folder: myFolders[index]),
                            ),
                          ).then((_) => setState(() {})); // 돌아왔을 때 화면 갱신
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFolderDialog,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.create_new_folder, color: Colors.white),
      ),
    );
  }
}

// 3. 폴더 안의 메모 목록 화면
class MemoListScreen extends StatefulWidget {
  final Folder folder;
  const MemoListScreen({super.key, required this.folder});

  @override
  State<MemoListScreen> createState() => _MemoListScreenState();
}

class _MemoListScreenState extends State<MemoListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folder.name),
      ),
      body: widget.folder.memos.isEmpty
          ? const Center(child: Text("메모가 없습니다. 새 메모를 작성해보세요!"))
          : ListView.builder(
              itemCount: widget.folder.memos.length,
              itemBuilder: (context, index) {
                var memo = widget.folder.memos[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(memo.title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(memo.content,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () {
                      // 메모 수정 모드로 진입
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MemoEditScreen(
                            folder: widget.folder,
                            existingMemo: memo,
                          ),
                        ),
                      ).then((_) => setState(() {}));
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 새 메모 작성 모드로 진입
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MemoEditScreen(folder: widget.folder),
            ),
          ).then((_) => setState(() {}));
        },
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// 4. 메모 작성 및 수정 화면
class MemoEditScreen extends StatefulWidget {
  final Folder folder;
  final Memo? existingMemo; // 이게 null이면 새 메모, 있으면 수정

  const MemoEditScreen({super.key, required this.folder, this.existingMemo});

  @override
  State<MemoEditScreen> createState() => _MemoEditScreenState();
}

class _MemoEditScreenState extends State<MemoEditScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    // 기존 메모가 있으면 그 내용을 불러오고, 없으면 빈 칸으로 시작
    _titleController =
        TextEditingController(text: widget.existingMemo?.title ?? "");
    _contentController =
        TextEditingController(text: widget.existingMemo?.content ?? "");
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveMemo() async {
    // 제목과 내용이 둘 다 비어있으면 저장 안 하고 뒤로가기
    if (_titleController.text.isEmpty && _contentController.text.isEmpty) {
      Navigator.pop(context);
      return;
    }

    if (widget.existingMemo == null) {
      // 새 메모 저장
      widget.folder.memos.add(
        Memo(title: _titleController.text, content: _contentController.text),
      );
    } else {
      // 기존 메모 수정
      widget.existingMemo!.title = _titleController.text;
      widget.existingMemo!.content = _contentController.text;
    }

    // 스마트폰에 바뀐 내용을 덮어쓰기!
    await saveFoldersData();

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingMemo == null ? "새 메모" : "메모 수정"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveMemo,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: "제목",
                border: InputBorder.none,
              ),
            ),
            const Divider(),
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null, // 줄바꿈 무제한
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  hintText: "내용을 입력하세요",
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
