// Copyright (c) 2026  Xiaomi Corporation
//
// C# bindings for piper-phonemize C API

using System;
using System.Runtime.InteropServices;
using System.Text;

namespace PiperPhonemize
{
    public class PiperPhonemizeApi : IDisposable
    {
        /// <summary>
        /// Get the piper-phonemize version string.
        /// </summary>
        public static string GetVersionStr()
        {
            IntPtr ptr = PiperPhonemizeGetVersionStr();
            return Marshal.PtrToStringAnsi(ptr);
        }

        /// <summary>
        /// Initialize espeak-ng with the given data directory.
        /// Must be called before any phonemization.
        /// </summary>
        /// <param name="dataDir">Path to espeak-ng-data directory.</param>
        /// <returns>Sample rate on first call, 0 on subsequent calls, or -1 on failure.</returns>
        public static int Initialize(string dataDir)
        {
            byte[] dataDirUtf8 = Encoding.UTF8.GetBytes(dataDir + '\0');
            return PiperPhonemizeInitialize(dataDirUtf8);
        }

        /// <summary>
        /// Phonemize text using espeak-ng.
        /// </summary>
        /// <param name="text">Text to phonemize (UTF-8).</param>
        /// <param name="voice">espeak-ng voice (e.g. "en-us"). Pass null or empty for default.</param>
        /// <returns>A PhonemizeResult, or null on failure.</returns>
        public static PhonemizeResult Text(string text, string voice = "en-us")
        {
            byte[] textUtf8 = Encoding.UTF8.GetBytes(text + '\0');
            byte[] voiceUtf8 = Encoding.UTF8.GetBytes((voice ?? "en-us") + '\0');
            IntPtr handle = PiperPhonemizeText(textUtf8, voiceUtf8);
            if (handle == IntPtr.Zero)
                return null;
            return new PhonemizeResult(handle);
        }

        #region Native methods (matching c-api.h)

        [DllImport(Dll.Filename)]
        private static extern IntPtr PiperPhonemizeGetVersionStr();

        [DllImport(Dll.Filename)]
        private static extern int PiperPhonemizeInitialize(byte[] dataDir);

        [DllImport(Dll.Filename)]
        private static extern IntPtr PiperPhonemizeText(byte[] text, byte[] voice);

        [DllImport(Dll.Filename)]
        internal static extern int PiperPhonemizeResultGetNumSentences(IntPtr result);

        [DllImport(Dll.Filename)]
        internal static extern int PiperPhonemizeResultGetNumPhonemes(IntPtr result, int sentenceId);

        [DllImport(Dll.Filename)]
        internal static extern IntPtr PiperPhonemizeResultGetPhonemes(IntPtr result, int sentenceId);

        [DllImport(Dll.Filename)]
        internal static extern void PiperPhonemizeDestroyResult(IntPtr result);

        #endregion

        #region IDisposable

        public void Dispose()
        {
            GC.SuppressFinalize(this);
        }

        #endregion
    }
}
