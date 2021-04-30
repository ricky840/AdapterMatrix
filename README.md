## Changelog
<dl>
  <dt type="adapter-version" label="certified-width_5.16.4">20.0.0.1</dt>
  <dd>
    <ul type="change-logs">
    	<li>Set MediaView's scale type to <code>CENTER_CROP</code> to fix native ad alignment issues.</li>
    </ul>
  </dd>

  <dt type="adapter-version" label="certified-with_5.16.4">20.0.0.0</dt>
  <dd>
    <ul type="change-logs">
    	<li>This version of the adapters has been certified with AdMob 20.0.0 and MoPub 5.16.4.</li>
    </ul>
  </dd>

  <dt type="adapter-version" label="certified-with_5.16.3">19.8.0.0</dt>
  <dd>
    <ul type="change-logs">
    	<li>This version of the adapters has been certified with AdMob 19.8.0 and MoPub 5.16.3.</li>
    	<li>Align impression tracking for non-native ad formats based on Google's <code>onAdImpression()</code> callback.</li>
    </ul>
  </dd>

  <dt type="adapter-version" label="certified-with_5.16.3">19.7.0.1</dt>
  <dd>
    <ul type="change-logs">
    	<li>Service release. No code changes.</li>
    </ul>
  </dd>

  <dt title="adapter-version" label="certified-with_5.16.0">19.7.0.0</dt>
  <dd>
    <ul title="change-logs">
    	<li>This version of the adapters has been certified with AdMob 19.7.0 and MoPub 5.16.0.</li>
    	<li>Refactor interstitial, rewarded video, and native based on new API guidelines from Google. No action items for publishers.</li>
    </ul>
  </dd>

  <dt title="adapter-version" label="certified-with_5.16.0">19.6.0.2</dt>
  <dd>
    <ul title="change-logs">
    	<li>Make <code>GooglePlayServicesNativeAd.java</code> public, and update the deprecated usage of <code>setMediaAspectRatio()</code> and <code>NativeAdOptions</code> orientations.</li>
    </ul>
  </dd>

  <dt title="adapter-version" label="certified-with_5.16.0">19.6.0.1</dt>
  <dd>
    <ul title="change-logs">
    	<li>Fix a bug where the rewarded video adapter fails to request a new ad after a show-related error happens.</li>
    </ul>
  </dd>

  <dt title="adapter-version" label="certified-with_5.15.0">19.6.0.0</dt>
  <dd>
    <ul title="change-logs">
    	<li>This version of the adapters has been certified with AdMob 19.6.0 and MoPub 5.15.0.</li>
    	<li>Remove the deprecated <code>onAdLeftApplication()</code> callback. As a result, click is no longer tracked for interstitial (in addition to rewarded video).</li>
    </ul>
  </dd>

  <dt title="adapter-version" label="certified-with_5.15.0">19.5.0.3</dt>
  <dd>
    <ul title="change-logs">
    	<li>Fail rewarded video playback errors using <code>VIDEO_PLAYBACK_ERROR</code> so publishers can request for the next rewarded video.</li>
    </ul>
  </dd>
</dl>
