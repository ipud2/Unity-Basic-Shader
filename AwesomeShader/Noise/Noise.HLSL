float3 hash33(float3 p3) 
{
	float3 p = fract(p3 * float3(.1031,.11369,.13787));
    p += dot(p, p.yxz+19.19);
    return -1.0 + 2.0 * fract(float3((p.x + p.y)*p.z, (p.x+p.z)*p.y, (p.y+p.z)*p.x));
}

float worley(float3 p, float scale)
{
    float3 id = floor(p*scale);
    float3 fd = fract(p*scale);

    float n = 0.;

    float minimalDist = 1.;


    for(float x = -1.; x <=1.; x++)
    {
        for(float y = -1.; y <=1.; y++)
        {
            for(float z = -1.; z <=1.; z++)
            {
                float3 coord = float3(x,y,z);
                float3 rId = hash33(mod(id+coord,scale))*0.5+0.5;
                float3 r = coord + rId - fd; 
                float d = dot(r,r);
                if(d < minimalDist)
                {
                    minimalDist = d;
                }

            }//z
        }//y
    }//x
    
    return 1.0-minimalDist;
}
