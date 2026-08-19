// Copyright (c) 2026  Xiaomi Corporation
//
// C# wrapper for piper-phonemize result handle

using System;
using System.Runtime.InteropServices;
using System.Text;

namespace PiperPhonemize
{
    public class PhonemizeResult : IDisposable
    {
        private IntPtr _handle;

        internal PhonemizeResult(IntPtr handle)
        {
            _handle = handle;
        }

        /// <summary>
        /// Number of sentences in the result.
        /// </summary>
        public int NumSentences
        {
            get
            {
                if (_handle == IntPtr.Zero)
                    return 0;
                return PiperPhonemizeApi.PiperPhonemizeResultGetNumSentences(_handle);
            }
        }

        /// <summary>
        /// Get phonemes for a sentence as a Unicode string.
        /// </summary>
        public string GetPhonemesAsString(int sentenceId)
        {
            if (_handle == IntPtr.Zero)
                return string.Empty;

            int count = PiperPhonemizeApi.PiperPhonemizeResultGetNumPhonemes(_handle, sentenceId);
            if (count <= 0)
                return string.Empty;

            IntPtr phonemesPtr = PiperPhonemizeApi.PiperPhonemizeResultGetPhonemes(_handle, sentenceId);
            if (phonemesPtr == IntPtr.Zero)
                return string.Empty;

            // Each phoneme is a uint32_t (Unicode code point)
            var sb = new StringBuilder(count);
            for (int i = 0; i < count; i++)
            {
                uint codePoint = (uint)Marshal.ReadInt32(phonemesPtr, i * 4);
                sb.Append(char.ConvertFromUtf32((int)codePoint));
            }
            return sb.ToString();
        }

        #region IDisposable

        public void Dispose()
        {
            Cleanup();
            GC.SuppressFinalize(this);
        }

        ~PhonemizeResult()
        {
            Cleanup();
        }

        private void Cleanup()
        {
            if (_handle != IntPtr.Zero)
            {
                PiperPhonemizeApi.PiperPhonemizeDestroyResult(_handle);
                _handle = IntPtr.Zero;
            }
        }

        #endregion
    }
}
