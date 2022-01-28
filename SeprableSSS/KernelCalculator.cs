using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class KernelCalculator
{
    /**
     * We use a falloff to modulate the shape of the profile. Big falloffs
     * spreads the shape making it wider, while small falloffs make it
     * narrower.
     */
    private static Vector3 Gaussian(float variance, float r, Vector3 falloff)
    {
        Vector3 g = Vector3.zero;
        for (int i = 0; i < 3; i++)
        {
            float rr = r / (0.001f + falloff[i]);
            g[i] = Mathf.Exp((-(rr * rr)) / (2.0f * variance)) / (2.0f * Mathf.PI * variance);
        }

        return g;
    }
    
    /**
     * We used the red channel of the original skin profile defined in
     * [d'Eon07] for all three channels. We noticed it can be used for green
     * and blue channels (scaled using the falloff parameter) without
     * introducing noticeable differences and allowing for total control over
     * the profile. For example, it allows to create blue SSS gradients, which
     * could be useful in case of rendering blue creatures.
     */
    private static Vector3 Profile(float r, Vector3 falloff)
    {
        return 0.100f * Gaussian(0.0484f, r, falloff) +
               0.118f * Gaussian(0.187f, r, falloff) +
               0.113f * Gaussian(0.567f, r, falloff) +
               0.358f * Gaussian(1.99f, r, falloff) +
               0.078f * Gaussian(7.41f, r, falloff);
    }

    public static List<Vector4> CalculateKernel(int nSamples, Vector3 strength, Vector3 falloff)
    {
        List<Vector4> kernel = new List<Vector4>();

        float RANGE = nSamples > 20 ? 3.0f : 2.0f;
        float EXPONENT = 2.0f;

        //calculate the offsets
        float step = 2.0f * RANGE / (nSamples - 1);
        for (int i = 0; i < nSamples; i++)
        {
            float o = -RANGE + i * step;
            float sign = o < 0.0f ? -1.0f : 1.0f;
            float w = RANGE * sign * Mathf.Abs(Mathf.Pow(o, EXPONENT)) / Mathf.Pow(RANGE, EXPONENT);
            kernel.Add(new Vector4(0, 0, 0, w));
        }

        //calculate the weights
        for (int i = 0; i < nSamples; i++)
        {
            float w0 = i > 0 ? Mathf.Abs(kernel[i].w - kernel[i - 1].w) : 0.0f;
            float w1 = i < nSamples - 1 ? Mathf.Abs(kernel[i].w - kernel[i + 1].w) : 0.0f;
            float area = (w0 + w1) / 2.0f;
            Vector3 temp = area * Profile(kernel[i].w, falloff);
            kernel[i] = new Vector4(temp.x, temp.y, temp.z, kernel[i].w);
        }

        //We want the offset 0.0 come first
        Vector4 t = kernel[nSamples / 2];
        for (int i = nSamples / 2; i > 0; i--)
        {
            kernel[i] = kernel[i - 1];
        }

        kernel[0] = t;
        
        //calculate the sum of the weights, we will need to normalize them below
        Vector4 sum = Vector4.zero;
        for (int i = 0; i < nSamples; i++)
        {
            sum += kernel[i];
        }
        
        //normalize the weight
        for (int i = 0; i < nSamples; i++)
        {
            Vector4 v = kernel[i];
            v.x /= sum.x;
            v.y /= sum.y;
            v.z /= sum.z;
            kernel[i] = v;
        }
        
        // Tweak them using the desired strength. The first one is:
        //      lerp(1.0, kernel[0].rgb, strength)
        Vector4 v0 = kernel[0];
        v0.x = (1.0f - strength.x) * 1.0f + strength.x * v0.x;
        v0.y = (1.0f - strength.y) * 1.0f + strength.y * v0.y;
        v0.z = (1.0f - strength.z) * 1.0f + strength.z * v0.z;
        kernel[0] = v0;

        // The others:
        //     lerp(0.0, kernel[0].rgb, strength)
        for (int i = 1; i < nSamples; i++)
        {
            Vector4 v = kernel[i];
            v.x *= strength.x;
            v.y *= strength.y;
            v.z *= strength.z;
            kernel[i] = v;
        }

        return kernel;
    }
}