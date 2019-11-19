package io.flutter.plugins.webviewflutter;

import android.os.Handler;
import android.os.Looper;
import android.webkit.WebResourceResponse;

import java.io.ByteArrayInputStream;
import java.util.Map;
import java.util.concurrent.CountDownLatch;

import io.flutter.plugin.common.MethodChannel;

public class SyncExecutor {
    private final CountDownLatch countDownLatch = new CountDownLatch(1);
    Handler mainHandler = new Handler(Looper.getMainLooper());
    WebResourceResponse res = null;

    public WebResourceResponse getResponse(final MethodChannel methodChannel, final String url) {
        res = null;
        mainHandler.post(new Runnable() {
            @Override
            public void run() {
                methodChannel.invokeMethod("shouldInterceptRequest", url, new MethodChannel.Result() {
                    @Override
                    public void success(Object o) {
                        if (o instanceof Map) {
                            Map<String, Object> map = (Map<String, Object>) o;
                            byte[] bytes = (byte[]) map.get("data");
                            String type = (String) map.get("mineType");
                            String encode = (String) map.get("encoding");
                            res = new WebResourceResponse(type, encode, new ByteArrayInputStream(bytes));
                        }
                        countDownLatch.countDown();
                    }

                    @Override
                    public void error(String s, String s1, Object o) {
                        res = null;
                        countDownLatch.countDown();
                    }

                    @Override
                    public void notImplemented() {
                        res = null;
                        countDownLatch.countDown();
                    }
                });

            }
        });
        try {
            countDownLatch.await();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        return res;
    }
}
