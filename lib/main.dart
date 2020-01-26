import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:web_notes/responsive_builder.dart';

// HIVE
const NOTES_BOX = "notes";
const NOTES_TYPE_ID = 0;

class Note {
  final String title;
  final String description;

  Note({
    this.title,
    this.description,
  });
}

class NoteAdapter extends TypeAdapter<Note> {
  @override
  Note read(BinaryReader reader) {
    final int numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Note(
      title: fields[0] as String,
      description: fields[1] as String,
    );
  }

  @override
  int get typeId => NOTES_TYPE_ID;

  @override
  void write(BinaryWriter writer, Note obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.description);
  }
}

// HIVE

// State

class CurrentNote extends ChangeNotifier {
  int _currentIndex;
  Note _note;

  int get currentIndex => _currentIndex;
  Note get note => _note;

  CurrentNote();

  void updateCurrentNote(int index, Note note) {
    _currentIndex = index;
    _note = note;
    notifyListeners();
  }

  void updateNote(Note note) {
    _note = note;
    final notesBox = Hive.box<Note>(NOTES_BOX);
    notesBox.put(_currentIndex, note);
  }
}

//

void main() async {
  if (!kIsWeb) {
    await Hive.initFlutter();
  }
  Hive.registerAdapter<Note>(NoteAdapter());
  await Hive.openBox<Note>(NOTES_BOX);
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentNote>(
            create: (BuildContext context) => CurrentNote(),
          )
        ],
        child: Home(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Notes'),
        elevation: 0.0,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () async {
              final currentNote =
                  Provider.of<CurrentNote>(context, listen: false);
              final note = Note(title: 'New Note');
              final index = await Hive.box<Note>(NOTES_BOX).add(note);
              currentNote.updateCurrentNote(index, note);
            },
          )
        ],
      ),
      body: ResponsiveBuilder(
        mobileBuilder: _buildMobile,
        desktopBuilder: _buildDesktop,
      ),
    );
  }

  Widget _buildMobile(BuildContext context) {
    return Consumer<CurrentNote>(
      builder: (context, currentNote, child) {
        return Row(
          children: <Widget>[
            Flexible(child: NotesList(
              onSelect: (index, note) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) {
                      return NoteEditorPage(
                        note: currentNote.note,
                        onUpdate: (note) {
                          currentNote.updateNote(note);
                        },
                      );
                    },
                  ),
                );
              },
            )),
          ],
        );
      },
    );
  }

  Widget _buildDesktop(BuildContext context) {
    return Consumer<CurrentNote>(
      builder: (context, currentNote, child) {
        return Row(
          children: <Widget>[
            Flexible(child: NotesList()),
            if (currentNote.note != null) ...[
              Container(
                width: 2.0,
                color: Colors.grey[200],
              ),
              Flexible(
                child: NoteEditorWidget(
                  note: currentNote.note,
                  onUpdate: (note) {
                    currentNote.updateNote(note);
                  },
                ),
              ),
            ]
          ],
        );
      },
    );
  }
}

class NotesListPage extends StatelessWidget {
  final Widget Function(int index, Note note) onSelect;

  const NotesListPage({
    Key key,
    this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notes'),
      ),
      body: NotesList(
        onSelect: this.onSelect,
      ),
    );
  }
}

class NotesList extends StatelessWidget {
  final void Function(int index, Note note) onSelect;

  const NotesList({
    Key key,
    this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Note>(NOTES_BOX).listenable(),
      builder: (context, Box<Note> box, widget) {
        return ListView.builder(
          itemCount: box.values.length,
          itemBuilder: (context, index) {
            final note = box.getAt(index);
            return NoteWidget(
              note: note,
              onSelect: () {
                final currentNote =
                    Provider.of<CurrentNote>(context, listen: false);
                currentNote.updateCurrentNote(index, note);
                if (this.onSelect != null) {
                  this.onSelect(index, note);
                }
              },
              onDelete: () {
                box.deleteAt(index);
              },
            );
          },
        );
      },
    );
  }
}

class NoteWidget extends StatelessWidget {
  final void Function() onSelect;
  final void Function() onDelete;
  final Note note;

  const NoteWidget({
    Key key,
    this.onSelect,
    this.onDelete,
    this.note,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: this.onSelect,
      onLongPress: this.onDelete,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final title = (note.title == null || note.title.isEmpty)
              ? "Empty Note..."
              : note.title;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 20.0,
                  ),
                ),
              ),
              Container(
                width: constraints.maxWidth,
                color: Colors.grey[200],
                height: 2.0,
              )
            ],
          );
        },
      ),
    );
  }
}

class NoteEditorPage extends StatelessWidget {
  final Note note;
  final void Function(Note note) onUpdate;

  const NoteEditorPage({
    Key key,
    this.note,
    this.onUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Note'),
      ),
      body: NoteEditorWidget(
        note: note,
        onUpdate: onUpdate,
      ),
    );
  }
}

class NoteEditorWidget extends StatefulWidget {
  final Note note;
  final void Function(Note note) onUpdate;

  const NoteEditorWidget({
    Key key,
    this.note,
    this.onUpdate,
  }) : super(key: key);

  @override
  _NoteEditorWidgetState createState() => _NoteEditorWidgetState();
}

class _NoteEditorWidgetState extends State<NoteEditorWidget> {
  final _titleEditingController = TextEditingController();
  final _descriptionEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleEditingController.addListener(_updateNote);
    _descriptionEditingController.addListener(_updateNote);
    _updateTextControllers();
  }

  @override
  void dispose() {
    super.dispose();
    _titleEditingController.dispose();
    _descriptionEditingController.dispose();
  }

  @override
  void didUpdateWidget(NoteEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateTextControllers();
  }

  void _updateTextControllers() {
    if (widget.note != null) {
      _titleEditingController.text = widget.note?.title;
      _descriptionEditingController.text = widget.note?.description;
    }
  }

  void _updateNote() {
    final note = Note(
      title: _titleEditingController.text,
      description: _descriptionEditingController.text,
    );
    widget.onUpdate(note);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: <Widget>[
          TextField(
            controller: _titleEditingController,
            decoration: InputDecoration(
              labelText: 'Title',
              border: InputBorder.none,
            ),
          ),
          Container(
            height: 2.0,
            color: Colors.grey[200],
          ),
          Expanded(
            child: Container(
              child: TextField(
                controller: _descriptionEditingController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
