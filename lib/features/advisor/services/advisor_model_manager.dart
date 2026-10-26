import 'package:flutter/foundation.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';

enum AdvisorModelStatus { unknown, notInstalled, downloading, ready, error }

class AdvisorModelManager extends ChangeNotifier {
  static const modelId = 'gemma-4-E2B-it';
  static const modelFileName = '$modelId.litertlm';
  static const modelUrl =
      'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/'
      'resolve/main/$modelFileName';
  static const approxSizeGb = 2.6;

  AdvisorModelStatus status = AdvisorModelStatus.unknown;
  double progress = 0;
  String? error;

  CancelToken? _cancelToken;

  bool get isReady => status == AdvisorModelStatus.ready;

  bool get isDownloading => status == AdvisorModelStatus.downloading;

  Future<void> refresh() async {
    try {
      final installed = await FlutterEdgeAi.isModelInstalled(modelId);

      status = installed
          ? AdvisorModelStatus.ready
          : AdvisorModelStatus.notInstalled;
      error = null;
    } catch (_) {
      status = AdvisorModelStatus.error;
      error = 'Could not check the AI model.';
    }

    notifyListeners();
  }

  Future<void> download() async {
    if (isDownloading || isReady) return;

    final token = CancelToken();
    _cancelToken = token;

    status = AdvisorModelStatus.downloading;
    progress = 0;
    error = null;
    notifyListeners();

    try {
      final installation =
          await FlutterEdgeAi.installModel(
            modelType: ModelType.gemma4,
            fileType: ModelFileType.litertlm,
          ).fromNetwork(modelUrl).withCancelToken(token).withProgress((
            percent,
          ) {
            progress = (percent / 100).clamp(0.0, 1.0).toDouble();
            notifyListeners();
          }).install();

      if (installation.modelId != modelId) {
        throw StateError('Unexpected model ID: ${installation.modelId}');
      }

      status = AdvisorModelStatus.ready;
      progress = 1;
    } catch (_) {
      if (token.isCancelled) {
        status = AdvisorModelStatus.notInstalled;
        error = null;
      } else {
        status = AdvisorModelStatus.error;
        error =
            'Download failed. Check your connection and storage, then retry.';
      }
    } finally {
      _cancelToken = null;
      notifyListeners();
    }
  }

  void cancelDownload() {
    _cancelToken?.cancel();
  }

  Future<void> delete() async {
    if (isDownloading) return;

    try {
      await FlutterEdgeAi.uninstallModel(modelId);
      status = AdvisorModelStatus.notInstalled;
      progress = 0;
      error = null;
    } catch (_) {
      status = AdvisorModelStatus.error;
      error = 'Could not delete the AI model.';
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }
}
