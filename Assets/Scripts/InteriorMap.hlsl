

float4 checkIfCloser(float3 rayDir, float3 rayStartPos, float3 planePos, float3 planeNormal, UnityTexture2D PlaneTex, float4 colorAndDist, UnitySamplerState ss, float roomCount)
{
    //Get the distance to the plane with ray-plane intersection
    //http://www.scratchapixel.com/lessons/3d-basic-rendering/minimal-ray-tracer-rendering-simple-shapes/ray-plane-and-ray-disk-intersection
    //We are always intersecting with the plane so we dont need to spend time checking that			
    float t = dot(planePos - rayStartPos, planeNormal) / dot(planeNormal, rayDir);

    //At what position is the ray intersecting with the plane - use this if you need uv coordinates
    float3 intersectPos = rayStartPos + rayDir * t;
    float2 ipos;

    //check the wall and assign the correct UV to ipos
    if( abs(planeNormal.x) == 1 ) // Left and Right wall
    ipos = float2(intersectPos.z, intersectPos.y);
    else if(abs(planeNormal.y) == 1) // Ceiling and floor
    ipos = float2(intersectPos.x, intersectPos.z);
    else    // Front and Back wall
    ipos = float2(planeNormal.z * intersectPos.x, intersectPos.y);
    

    //If the distance is closer to the camera than the previous best distance
    if (t < colorAndDist.w)
    {
        //This distance is now the best distance
        colorAndDist.w = t;

        //Set the color that belongs to this wall				
        colorAndDist.rgb = SAMPLE_TEXTURE2D(PlaneTex, ss, ipos * roomCount); 
    }

    return colorAndDist;
}

void InteriorMapping_float(float3 objectViewDir, float3 objectPos, float roomCount, UnitySamplerState ss,
UnityTexture2D TexTop, UnityTexture2D TexBottom, UnityTexture2D TexRight, UnityTexture2D TexLeft, UnityTexture2D Texfront, UnityTexture2D TexBack,  out float4 colorAndDist)
{
    //The view direction of the camera to this fragment in local space
    float3 rayDir = normalize(objectViewDir);

    //The local position of this fragment
    float3 rayStartPos = objectPos;

    //Important to start inside the house or we will display one of the outer walls
    rayStartPos += rayDir * 0.0001;


    //Init the loop with a float4 to make it easier to return from a function
    //colorAndDist.rgb is the color that will be displayed
    //colorAndDist.w is the shortest distance to a wall so far so we can find which wall is the closest
    colorAndDist = float4(float3(1,1,1), 100000000.0);

    float wallDistance = 1/roomCount;

    float3 upVec = float3(0, 1, 0);	
    float3 rightVec = float3(1, 0, 0);
    float3 forwardVec = float3(0, 0, 1);


    //Intersection 1: Wall / roof (y)
    //Camera is looking up if the dot product is > 0 = Roof
    if (dot(upVec, rayDir) > 0)
    {				
        //The local position of the roof
        float3 wallPos = (ceil(rayStartPos.y / wallDistance) * wallDistance) * upVec;

        //Check if the roof is intersecting with the ray, if so set the color and the distance to the roof and return it
        colorAndDist = checkIfCloser(rayDir, rayStartPos, wallPos, upVec, TexTop, colorAndDist, ss, roomCount);
    }
    //Floor
    else
    {
        float3 wallPos = ((ceil(rayStartPos.y / wallDistance) - 1.0) * wallDistance) * upVec;

        colorAndDist = checkIfCloser(rayDir, rayStartPos, wallPos, upVec * -1, TexBottom, colorAndDist, ss, roomCount);
        //colorAndDist = checkIfCloser(rayDir, rayStartPos, wallPos, upVec * -1, color1, colorAndDist);
    }
    

    //Intersection 2: Right wall (x)
    if (dot(rightVec, rayDir) > 0)
    {
        float3 wallPos = (ceil(rayStartPos.x / wallDistance) * wallDistance) * rightVec;

        colorAndDist = checkIfCloser(rayDir, rayStartPos, wallPos, rightVec, TexRight, colorAndDist, ss, roomCount);
    }
    else
    {
        float3 wallPos = ((ceil(rayStartPos.x / wallDistance) - 1.0) * wallDistance) * rightVec;

        colorAndDist = checkIfCloser(rayDir, rayStartPos, wallPos, rightVec * -1, TexLeft, colorAndDist, ss, roomCount);
    }


    //Intersection 3: Forward wall (z)
    if (dot(forwardVec, rayDir) > 0)
    {
        float3 wallPos = (ceil(rayStartPos.z / wallDistance) * wallDistance) * forwardVec;

        colorAndDist = checkIfCloser(rayDir, rayStartPos, wallPos, forwardVec, Texfront, colorAndDist, ss, roomCount);
    }
    else
    {
        float3 wallPos = ((ceil(rayStartPos.z / wallDistance) - 1.0) * wallDistance) * forwardVec;

        colorAndDist = checkIfCloser(rayDir, rayStartPos, wallPos, forwardVec * -1, TexBack, colorAndDist, ss, roomCount);
    }   
    

    
}

