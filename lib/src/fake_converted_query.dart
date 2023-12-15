// ignore: subtype_of_sealed_class
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';

import 'converter.dart';
import 'fake_query_with_parent.dart';
import 'mock_document_change.dart';
import 'mock_query_snapshot.dart';

// ignore: subtype_of_sealed_class
/// A converted query. It should always be the last query in the chain, so we
/// don't need to implement where, startAt, ..., withConverter.
class FakeConvertedQuery<T extends Object?> extends FakeQueryWithParent<T> {
  final FakeQueryWithParent _nonConvertedParentQuery;
  final Converter<T> _converter;

  FakeConvertedQuery(this._nonConvertedParentQuery, this._converter)
      : assert(_nonConvertedParentQuery is Query<Map<String, dynamic>>,
            'FakeConvertedQuery expects a non-converted query.');

  @override
  Future<QuerySnapshot<T>> get([GetOptions? options]) async {
    final rawDocSnapshots = (await _nonConvertedParentQuery.get()).docs;
    final convertedSnapshots = rawDocSnapshots
        .map((rawDocSnapshot) => rawDocSnapshot.reference
            .withConverter<T>(
                fromFirestore: _converter.fromFirestore,
                toFirestore: _converter.toFirestore)
            .get())
        .toList();
    final docs = await Future.wait(convertedSnapshots);
    return MockQuerySnapshot(
      docs,
      options?.source == Source.cache,
      documentChanges: docs.mapIndexed((index, e) {
        return MockDocumentChange<T>(e, DocumentChangeType.added, oldIndex: -1, newIndex: index);
      }).toList(),
    );
  }

  @override
  FakeQueryWithParent? get parentQuery => _nonConvertedParentQuery;

  @override
  Query<T> limit(int limit) {
    return FakeConvertedQuery<T>(
        _nonConvertedParentQuery.limit(limit) as FakeQueryWithParent,
        _converter);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
