// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.task.inputs;

import 'dart:collection';

import 'package:analyzer/task/model.dart';

/**
 * A function that converts an object of the type [B] into a [TaskInput].
 * This is used, for example, by a [ListToListTaskInput] to create task inputs
 * for each value in a list of values.
 */
typedef TaskInput<E> GenerateTaskInputs<B, E>(B object);

/**
 * An input to an [AnalysisTask] that is computed by accessing a single result
 * defined on a single target.
 */
class ListTaskInputImpl<E> extends SimpleTaskInput<List<E>>
    with ListTaskInputMixin<E> implements ListTaskInput<E> {
  /**
   * Initialize a newly created task input that computes the input by accessing
   * the given [result] associated with the given [target].
   */
  ListTaskInputImpl(AnalysisTarget target, ResultDescriptor<List<E>> result)
      : super(target, result);
}

/**
 * A mixin-ready implementation of [ListTaskInput].
 */
abstract class ListTaskInputMixin<E> implements ListTaskInput<E> {
  ListTaskInput /*<V>*/ toList(UnaryFunction<E, dynamic /*<V>*/ > mapper) {
    return new ListToListTaskInput<E, dynamic /*V*/ >(this, mapper);
  }

  ListTaskInput /*<V>*/ toListOf(ResultDescriptor /*<V>*/ valueResult) {
    return (this as ListTaskInputImpl<AnalysisTarget>).toList(valueResult.of);
  }

  TaskInput<Map<E, dynamic /*V*/ >> toMap(
      UnaryFunction<E, dynamic /*<V>*/ > mapper) {
    return new ListToMapTaskInput<E, dynamic /*V*/ >(this, mapper);
  }

  TaskInput<Map<AnalysisTarget, dynamic /*V*/ >> toMapOf(
      ResultDescriptor /*<V>*/ valueResult) {
    return (this as ListTaskInputImpl<AnalysisTarget>).toMap(valueResult.of);
  }
}

/**
 * An input to an [AnalysisTask] that is computed by the following steps. First
 * another (base) task input is used to compute a [List]-valued result. An input
 * generator function is then used to map each element of that list to a task
 * input. Finally, each of the task inputs are used to access analysis results,
 * and the list of the analysis results is used as the input to the task.
 */
class ListToListTaskInput<B, E>
    extends _ListToCollectionTaskInput<B, E, List<E>>
    with ListTaskInputMixin<E> {
  /**
   * Initialize a result accessor to use the given [baseAccessor] to access a
   * list of values that can be passed to the given [generateTaskInputs] to
   * generate a list of task inputs that can be used to access the elements of
   * the input being accessed.
   */
  ListToListTaskInput(TaskInput<List<B>> baseAccessor,
      GenerateTaskInputs<B, E> generateTaskInputs)
      : super(baseAccessor, generateTaskInputs);

  @override
  TaskInputBuilder<List<E>> createBuilder() =>
      new ListToListTaskInputBuilder<B, E>(this);
}

/**
 * A [TaskInputBuilder] used to build an input based on a [ListToListTaskInput].
 */
class ListToListTaskInputBuilder<B, E>
    extends _ListToCollectionTaskInputBuilder<B, E, List<E>> {
  /**
   * The list of values being built.
   */
  List<E> _resultValue;

  /**
   * Initialize a newly created task input builder that computes the result
   * specified by the given [input].
   */
  ListToListTaskInputBuilder(ListToListTaskInput<B, E> input) : super(input);

  @override
  void _addResultElement(B baseElement, E resultElement) {
    _resultValue.add(resultElement);
  }

  @override
  void _initResultValue() {
    _resultValue = <E>[];
  }
}

/**
 * An input to an [AnalysisTask] that is computed by the following steps. First
 * another (base) task input is used to compute a [List]-valued result. An input
 * generator function is then used to map each element of that list to a task
 * input. Finally, each of the task inputs are used to access analysis results,
 * and the map of the base elements to the analysis results is used as the
 * input to the task.
 */
class ListToMapTaskInput<B, E>
    extends _ListToCollectionTaskInput<B, E, Map<B, E>> {
  /**
   * Initialize a result accessor to use the given [baseAccessor] to access a
   * list of values that can be passed to the given [generateTaskInputs] to
   * generate a list of task inputs that can be used to access the elements of
   * the input being accessed.
   */
  ListToMapTaskInput(TaskInput<List<B>> baseAccessor,
      GenerateTaskInputs<B, E> generateTaskInputs)
      : super(baseAccessor, generateTaskInputs);

  @override
  TaskInputBuilder<Map<B, E>> createBuilder() =>
      new ListToMapTaskInputBuilder<B, E>(this);
}

/**
 * A [TaskInputBuilder] used to build an input based on a [ListToMapTaskInput].
 */
class ListToMapTaskInputBuilder<B, E>
    extends _ListToCollectionTaskInputBuilder<B, E, Map<B, E>> {
  /**
   * The map being built.
   */
  Map<B, E> _resultValue;

  /**
   * Initialize a newly created task input builder that computes the result
   * specified by the given [input].
   */
  ListToMapTaskInputBuilder(ListToMapTaskInput<B, E> input) : super(input);

  @override
  void _addResultElement(B baseElement, E resultElement) {
    _resultValue[baseElement] = resultElement;
  }

  @override
  void _initResultValue() {
    _resultValue = new HashMap<B, E>();
  }
}

/**
 * An input to an [AnalysisTask] that is computed by accessing a single result
 * defined on a single target.
 */
class SimpleTaskInput<V> implements TaskInput<V> {
  /**
   * The target on which the result is defined.
   */
  final AnalysisTarget target;

  /**
   * The result to be accessed.
   */
  final ResultDescriptor<V> result;

  /**
   * Initialize a newly created task input that computes the input by accessing
   * the given [result] associated with the given [target].
   */
  SimpleTaskInput(this.target, this.result);

  @override
  TaskInputBuilder<V> createBuilder() => new SimpleTaskInputBuilder<V>(this);
}

/**
 * A [TaskInputBuilder] used to build an input based on a [SimpleTaskInput].
 */
class SimpleTaskInputBuilder<V> implements TaskInputBuilder<V> {
  /**
   * The state value indicating that the builder is positioned before the single
   * result.
   */
  static const _BEFORE = -1;

  /**
   * The state value indicating that the builder is positioned at the single
   * result.
   */
  static const _AT = 0;

  /**
   * The state value indicating that the builder is positioned after the single
   * result.
   */
  static const _AFTER = 1;

  /**
   * The input being built.
   */
  final SimpleTaskInput<V> input;

  /**
   * The value of the input being built.
   */
  V _resultValue = null;

  /**
   * The state of the builder.
   */
  int _state = _BEFORE;

  /**
   * A flag indicating whether the result value was explicitly set.
   */
  bool _resultSet = false;

  /**
   * Initialize a newly created task input builder that computes the result
   * specified by the given [input].
   */
  SimpleTaskInputBuilder(this.input);

  @override
  ResultDescriptor get currentResult => _state == _AT ? input.result : null;

  @override
  AnalysisTarget get currentTarget => _state == _AT ? input.target : null;

  @override
  void set currentValue(Object value) {
    if (_state != _AT) {
      throw new StateError(
          'Cannot set the result value when there is no current result');
    }
    _resultValue = value as V;
    _resultSet = true;
  }

  @override
  V get inputValue {
    if (_state != _AFTER) {
      throw new StateError('Result value has not been created');
    }
    return _resultValue;
  }

  @override
  bool moveNext() {
    if (_state == _BEFORE) {
      _state = _AT;
      return true;
    } else {
      if (!_resultSet) {
        throw new StateError(
            'The value of the current result must be set before moving to the next result.');
      }
      _state = _AFTER;
      return false;
    }
  }
}

/**
 * A [TaskInputBuilder] used to build an input based on one or more other task
 * inputs. The task inputs to be built are specified by a table mapping the name
 * of the input to the task used to access the input's value.
 */
class TopLevelTaskInputBuilder
    implements TaskInputBuilder<Map<String, Object>> {
  /**
   * The descriptors describing the inputs to be built.
   */
  final Map<String, TaskInput> inputDescriptors;

  /**
   * The names of the inputs. There are the keys from the [inputDescriptors] in
   * an indexable form.
   */
  List<String> inputNames;

  /**
   * The index of the input name associated with the current result and target.
   */
  int nameIndex = -1;

  /**
   * The builder used to build the current result.
   */
  TaskInputBuilder currentBuilder;

  /**
   * The inputs that are being or have been built. The map will be incomplete
   * unless the method [moveNext] returns `false`.
   */
  final Map<String, Object> inputs = new HashMap<String, Object>();

  /**
   * Initialize a newly created task input builder to build the inputs described
   * by the given [inputDescriptors].
   */
  TopLevelTaskInputBuilder(this.inputDescriptors) {
    inputNames = inputDescriptors.keys.toList();
  }

  @override
  ResultDescriptor get currentResult {
    if (currentBuilder == null) {
      return null;
    }
    return currentBuilder.currentResult;
  }

  @override
  AnalysisTarget get currentTarget {
    if (currentBuilder == null) {
      return null;
    }
    return currentBuilder.currentTarget;
  }

  @override
  void set currentValue(Object value) {
    if (currentBuilder == null) {
      throw new StateError(
          'Cannot set the result value when there is no current result');
    }
    currentBuilder.currentValue = value;
  }

  @override
  Map<String, Object> get inputValue {
    if (nameIndex < inputNames.length) {
      throw new StateError('Result value has not been created');
    }
    return inputs;
  }

  /**
   * Assuming that there is a current input, return its name.
   */
  String get _currentName => inputNames[nameIndex];

  @override
  bool moveNext() {
    if (nameIndex >= inputNames.length) {
      // We have already computed all of the results, so just return false.
      return false;
    }
    if (nameIndex < 0) {
      // This is the first time moveNext has been invoked, so we just determine
      // whether there are any results to be computed.
      nameIndex = 0;
    } else {
      if (currentBuilder.moveNext()) {
        // We are still working on building the value associated with the
        // current name.
        return true;
      }
      inputs[_currentName] = currentBuilder.inputValue;
      nameIndex++;
    }
    if (nameIndex >= inputNames.length) {
      // There is no next value, so we're done.
      return false;
    }
    currentBuilder = inputDescriptors[_currentName].createBuilder();
    // NOTE: This assumes that every builder will require at least one result
    // value to be created. If that assumption is every broken, this method will
    // need to be changed to advance until we find a builder that does require
    // a result to be computed (or run out of builders).
    return currentBuilder.moveNext();
  }
}

/**
 * An input to an [AnalysisTask] that is computed by the following steps. First
 * another (base) task input is used to compute a [List]-valued result. An input
 * generator function is then used to map each element of that list to a task
 * input. Finally, each of the task inputs are used to access analysis results,
 * and a collection of the analysis results is used as the input to the task.
 */
abstract class _ListToCollectionTaskInput<B, E, C> implements TaskInput<C> {
  /**
   * The accessor used to access the list of elements being mapped.
   */
  final TaskInput<List<B>> baseAccessor;

  /**
   * The function used to convert an element in the list returned by the
   * [baseAccessor] to a task input.
   */
  final GenerateTaskInputs<B, E> generateTaskInputs;

  /**
   * Initialize a result accessor to use the given [baseAccessor] to access a
   * list of values that can be passed to the given [generateTaskInputs] to
   * generate a list of task inputs that can be used to access the elements of
   * the input being accessed.
   */
  _ListToCollectionTaskInput(this.baseAccessor, this.generateTaskInputs);
}

/**
 * A [TaskInputBuilder] used to build an [_ListToCollectionTaskInput].
 */
abstract class _ListToCollectionTaskInputBuilder<B, E, C>
    implements TaskInputBuilder<C> {
  /**
   * The input being built.
   */
  final _ListToCollectionTaskInput<B, E, C> input;

  /**
   * The builder used to build the current result.
   */
  TaskInputBuilder currentBuilder;

  /**
   * The list of values computed by the [input]'s base accessor.
   */
  List<B> _baseList = null;

  /**
   * The index in the [_baseList] of the value for which a value is currently
   * being built.
   */
  int _baseListIndex = -1;

  /**
   * The element of the [_baseList] for which a value is currently being built.
   */
  B _baseListElement;

  /**
   * Initialize a newly created task input builder that computes the result
   * specified by the given [input].
   */
  _ListToCollectionTaskInputBuilder(this.input);

  @override
  ResultDescriptor get currentResult {
    if (currentBuilder == null) {
      return null;
    }
    return currentBuilder.currentResult;
  }

  @override
  AnalysisTarget get currentTarget {
    if (currentBuilder == null) {
      return null;
    }
    return currentBuilder.currentTarget;
  }

  @override
  void set currentValue(Object value) {
    if (currentBuilder == null) {
      throw new StateError(
          'Cannot set the result value when there is no current result');
    }
    currentBuilder.currentValue = value;
  }

  @override
  C get inputValue {
    if (currentBuilder != null || _resultValue == null) {
      throw new StateError('Result value has not been created');
    }
    return _resultValue;
  }

  /**
   * The list of values being built.
   */
  C get _resultValue;

  @override
  bool moveNext() {
    if (currentBuilder == null) {
      if (_resultValue == null) {
        // This is the first time moveNext has been invoked, so start by
        // computing the list of values from which the results will be derived.
        currentBuilder = input.baseAccessor.createBuilder();
        return currentBuilder.moveNext();
      } else {
        // We have already computed all of the results, so just return false.
        return false;
      }
    }
    if (currentBuilder.moveNext()) {
      return true;
    }
    if (_resultValue == null) {
      // We have finished computing the list of values from which the results
      // will be derived.
      _baseList = currentBuilder.inputValue;
      _baseListIndex = 0;
      _initResultValue();
    } else {
      // We have finished computing one of the elements in the result list.
      _addResultElement(_baseListElement, currentBuilder.inputValue);
      _baseListIndex++;
    }
    if (_baseListIndex >= _baseList.length) {
      currentBuilder = null;
      return false;
    }
    _baseListElement = _baseList[_baseListIndex];
    currentBuilder = input.generateTaskInputs(_baseListElement).createBuilder();
    return currentBuilder.moveNext();
  }

  void _addResultElement(B baseElement, E resultElement);
  void _initResultValue();
}
