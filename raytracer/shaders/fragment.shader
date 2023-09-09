#version 460

#define epsilon 0.0000001

const int height = 1080;
const int width = 1080;


out vec3 color;

in vec2 textCoord;

uniform sampler2D screenTexture;

uniform int frameNumber;

uniform bool directOutPass;
uniform float sphereVertical;
uniform bool useNormals;

//uniform vec3 vertices[47];
//uniform vec3 normals[1];
//uniform ivec3 faces[83];
//uniform ivec3 normalIndices[1];

//uniform vec3 vertices[235];
//uniform vec3 normals[1];
//uniform ivec3 faces[456];
//uniform ivec3 normalIndices[1];

uniform vec3 camPos;
uniform vec3 vertices[507];
uniform vec3 normals[1];
//uniform ivec3 faces[510];
uniform ivec3 normalIndices[1];

//uniform vec3 camPos;
////uniform vec3 vertices[2503];
//uniform vec3 normals[1];
//uniform ivec3 faces[4968];
//uniform ivec3 normalIndices[1];

uniform int verticesSize;
uniform int normalsSize;
uniform int facesSize;
uniform int normalIndicesSize;
uniform int rotateDeg;

//layout(std140, binding = 0) uniform MyUBO{
//    vec3 vertices[235];
//};

layout(std430, binding = 0) buffer VertexBuffer {
    ivec3 faces[];
};


struct ray {
    bool noRay;
    vec3 direction;
    vec3 origin;
};

ray createRay(vec3 o, vec3 d) {
    ray r;
    r.origin = o;
    r.direction = normalize(d);
    return r;
}

struct material {
    vec3 color;
    vec3 emittance;
    float smoothness;
};

material createMaterial(vec3 c, vec3 e, float s) {
    material m;
    m.color = c;
    m.emittance = e;
    m.smoothness = s;
    return m;
}

struct sphere {
    float radius;
    vec3 center;
    material material;
};

sphere createSphere(float r, vec3 c, material m) {
    sphere s;
    s.radius = r;
    s.center = c;
    s.material = m;
    return s;
}

struct triangle {
    vec3 v1;
    vec3 v2;
    vec3 v3;
    vec3 vn1;
    vec3 vn2;
    vec3 vn3;
    material material;
};

triangle createTriangle(vec3 v1, vec3 v2, vec3 v3, material m){
    triangle tri;
    tri.v1 = v1;
    tri.v2 = v2;
    tri.v3 = v3;
    tri.material = m;
    return tri;
}

triangle createTriangleNormal(vec3 v1, vec3 v2, vec3 v3, vec3 vn1, vec3 vn2, vec3 vn3, material m) {
    triangle tri;
    tri.v1 = v1;
    tri.v2 = v2;
    tri.v3 = v3;
    tri.vn1 = vn1;
    tri.vn2 = vn2;
    tri.vn3 = vn3;
    tri.material = m;
    return tri;
}

struct camera {
    float fov;
    float aspectRatio;
    float h;
    float viewportHeight;
    float viewportWidth;
    float focalLength;
    vec3 origin;
    vec3 lowerLeft;
    vec3 horizontal;
    vec3 vertical;
};

camera createCamera(float f, float aR, vec3 pos) {
    camera c;
    c.fov = f;
    c.aspectRatio = aR;

    c.h = tan(radians(f / 2));
    c.viewportHeight = 2 * c.h;
    c.viewportWidth = aR * c.viewportHeight;
    c.focalLength = 1;

    c.origin = pos;
    c.horizontal = vec3(c.viewportWidth, 0, 0);
    c.vertical = vec3(0, c.viewportHeight, 0);
    c.lowerLeft = c.origin - c.horizontal / 2 - c.vertical / 2 - vec3(0, 0, c.focalLength);

    return c;
}

ray createCameraRay(float u, float v, camera c) {
    ray r = createRay(c.origin, c.lowerLeft + u * c.horizontal + v * c.vertical - c.origin);
    return r;
}

mat3 rotateUp(float angle) {
    float c = cos(radians(angle));
    float s = sin(radians(angle));
    return mat3(
        c, 0, -s,
        0, 1, 0,
        s, 0, c
    );
}

mat3 rotateRight(float angle) {
    float c = cos(radians(angle));
    float s = sin(radians(angle));
    return mat3(
        c, s, 0,
        -s, c, 0,
        0, 0, 1
    );
}

vec4 quaternionMultiply(vec4 a, vec4 b) {
    return vec4(
        a.w * b.xyz + b.w * a.xyz + cross(a.xyz, b.xyz),
        a.w * b.w - dot(a.xyz, b.xyz)
    );
}

vec3 quaternionRotation(vec3 axis, vec3 p, float angle) { //might need to z up instead of y
    float halfAngle = radians(angle) / 2;
    vec4 q = vec4(sin(halfAngle) * axis, cos(halfAngle));
    vec4 qInv = vec4(-q.xyz,q.w);
    vec4 rotate = quaternionMultiply(quaternionMultiply(q, vec4(p,0.0)), qInv);
    return rotate.xyz;
}

struct hit {
    bool didHit;
    float distance;
    vec3 hitPoint;
    vec3 normal;
    material objectMaterial;
};

hit triangleIntersect(ray r, triangle tri) {
    hit result;
    vec3 edge1 = tri.v2 - tri.v1;
    vec3 edge2 = tri.v3 - tri.v1;
    vec3 h = cross(r.direction, edge2);
    float a = dot(edge1, h);

    if (a > -epsilon && a < epsilon) {
        result.didHit = false;
        return result;
    }

    float f = 1.0 / a;
    vec3 s = r.origin - tri.v1;
    float u = f * dot(s, h);

    if (u < 0.0 || u > 1.0) {
        result.didHit = false;
        return result;
    }

    vec3 q = cross(s, edge1);
    float v = f * dot(r.direction, q);

    if (v < 0.0 || u + v > 1.0) {
        result.didHit = false;
        return result;
    }

    float t = f * dot(edge2, q);
    if (t > epsilon) // ray intersection
    {
        result.hitPoint = r.origin + r.direction * t;
        result.didHit = true;
        result.distance = t;
        result.objectMaterial = tri.material;
        vec3 N = normalize(cross(edge1, edge2));
        float normalDot = dot(N, N);
        result.normal = N;
        if (false)
            result.normal = -N; //may need to change
        /*}else if (a < 0) {
            result.normal = N;
        }*/
        return result;
    }
    else {
        result.didHit = false;
        return result;
    }
}

//hit triangleIntersectNormal(ray r, triangle tri) {
//    hit result;
//    vec3 edge1 = tri.v2 - tri.v1;
//    vec3 edge2 = tri.v3 - tri.v1;
//    vec3 N = normalize(cross(edge1, edge2));
//    vec3 ao = r.origin - tri.v1;
//    vec3 dao = cross(ao, r.direction);
//
//    float det = -dot(r.direction, N);
//    float invDet = 1.0 / det;
//
//    float u = dot(edge2, dao) * invDet;
//    float v = -dot(edge1, dao) * invDet;
//
//    float w = 1.0 - u - v;
//
//    result.distance = dot(ao, N) * invDet;
//    result.didHit = det > epsilon && result.distance >= 0 && u >= 0 && v >= 0 && w >= 0;
//    result.hitPoint = r.origin + r.direction * result.distance;
//    result.normal = normalize(tri.vn1*w + tri.vn2*u + tri.vn3*v);
//    result.objectMaterial = tri.material;
//    return result;
//
//
//}

hit triangleIntersectNormal(ray r, triangle tri) {
    hit result;
    vec3 edge1 = tri.v2 - tri.v1;
    vec3 edge2 = tri.v3 - tri.v1;
    vec3 h = cross(r.direction, edge2);
    float a = dot(edge1, h);

    if (a > -epsilon && a < epsilon) {
        result.didHit = false;
        return result;
    }

    float f = 1.0 / a;
    vec3 s = r.origin - tri.v1;
    float u = f * dot(s, h);

    if (u < 0.0 || u > 1.0) {
        result.didHit = false;
        return result;
    }

    vec3 q = cross(s, edge1);
    float v = f * dot(r.direction, q);

    if (v < 0.0 || u + v > 1.0) {
        result.didHit = false;
        return result;
    }

    float t = f * dot(edge2, q);
    if (t > epsilon) // ray intersection
    {
        result.hitPoint = r.origin + r.direction * t;
        result.didHit = true;
        result.distance = t;
        result.objectMaterial = tri.material;
        result.normal = tri.vn1;
        return result;
    }
    else {
        result.didHit = false;
        return result;
    }
}

hit sphereIntersect(ray r, sphere s) {
    hit h;
    float t = 0;
    vec3 v = r.origin - s.center;
    float vdotd = dot(v, r.direction);
    if (vdotd > 0) {
        h.didHit = false;
        return h;
    }
    float discriminant = vdotd * vdotd - (dot(v, v) - s.radius * s.radius);
    if (discriminant < 0) {
        h.didHit = false;
        return h;
    }
    float t1 = -1 * vdotd - sqrt(discriminant);
    float t2 = -1 * vdotd + sqrt(discriminant);
    if (t1 > 0) {
        t = t1;
        h.didHit = true;
    }
    else if (t2 > 0) {
        t = t2;
        h.didHit = true;
    }
    else {
        h.didHit = false;
        return h;
    }
    h.distance = t;
    h.hitPoint = r.origin + r.direction * t;
    h.normal = (h.hitPoint - s.center) / s.radius;
    h.objectMaterial = s.material;
    return h;
}

float random(inout uint state)
{
    state = state * uint(747796405) + uint(2891336453);
    uint result = ((state >> ((state >> uint(28)) + uint(4))) ^ state) * uint(277803737);
    result = (result >> uint(22)) ^ result;
    return result / 4294967295.0;
}

float randNormalDist(inout uint state) {
    float theta = radians(360.0) * random(state);
    float rho = sqrt(-2 * log(random(state)));
    return rho * cos(theta);
}

vec3 randDirection(inout uint state) {
    return normalize(vec3(randNormalDist(state), randNormalDist(state), randNormalDist(state)));
}

const int sphereNum = 1;
sphere spheres[sphereNum];


//const int triangleNum = 1;
//triangle triangles[triangleNum];

const bool useBox = true;

vec3 boxVertices[8] = {
    vec3(3.000000, 3.000000, -3.000000),
    vec3(3.000000, -3.000000, -3.000000),
    vec3(3.000000, 3.000000, 3.000000),
    vec3(3.000000, -3.000000, 3.000000),
    vec3(-3.000000, 3.000000, -3.000000), 
    vec3(-3.000000, -3.000000, -3.000000),
    vec3(-3.000000, 3.000000, 3.000000),
    vec3(-3.000000, -3.000000, 3.000000)
};
ivec3 boxIndices[12] = {
    ivec3(3, 5, 1),
    ivec3(6, 7, 8),
    ivec3(8, 2, 6),
    ivec3(4, 1, 2),
    ivec3(2, 5, 6), 
    ivec3(7, 5, 3),
    ivec3(5, 7, 6), 
    ivec3(4, 2, 8),
    ivec3(3, 1, 4),
    ivec3(1, 5, 2), 
    ivec3(8, 3, 4),
    ivec3(7, 3, 8)
};
vec3 boxColor[12] = {
    vec3(1,1,1),
    vec3(1,0,0),
    vec3(1,1,1),
    vec3(0,1,0),
    vec3(1,1,1),
    vec3(1,1,1),
    vec3(1,0,0),
    vec3(1,1,1),
    vec3(0,1,0),
    vec3(1,1,1),
    vec3(1,1,1),
    vec3(1,1,1)
};
vec3 planeVertices[4] = {
    vec3(-1.00000, 2.9, 1.00000),
    vec3(1.00000, 2.9, 1.00000),
    vec3(-1.00000, 2.9, - 1.00000),
    vec3(1.00000, 2.9, - 1.00000)
};
ivec3 planeIndices[2] = {
    ivec3(2, 3, 1),
    ivec3(2, 4, 3)
};

hit collision(ray r) {
    float minDist = 1.0 / 0.0;
    hit result;
    for (int i = 0; i < sphereNum; i++) {
        hit h = sphereIntersect(r, spheres[i]);
        if (h.didHit && h.distance < minDist) {
            minDist = h.distance;
            result = h;
        }
    }
    for (int i = 0; i < facesSize; i++) {
        hit h;
        /*if (useNormals) {
            h = triangleIntersectNormal(r, createTriangleNormal(vertices[faces[i].x - 1], vertices[faces[i].y - 1], vertices[faces[i].z - 1], normals[normalIndices[i].x - 1], normals[normalIndices[i].y - 1], normals[normalIndices[i].z - 1], createMaterial(vec3(1, 1, 1), vec3(0, 0, 0), 0.0)));
        }
        else {*/
            /*vec3 axis = vec3(1, 1, 1);
            h = triangleIntersect(r, createTriangle(quaternionRotation(axis, vertices[faces[i].x - 1], rotateDeg), quaternionRotation(axis, vertices[faces[i].y - 1], rotateDeg), quaternionRotation(axis, vertices[faces[i].z - 1], rotateDeg), createMaterial(vec3(1, 1, 1), vec3(0, 0, 0), 0.0)));
        */
            h = triangleIntersect(r, createTriangle(vertices[faces[i].x - 1],vertices[faces[i].y - 1],vertices[faces[i].z - 1], createMaterial(vec3(1, 1, 1), vec3(0, 0, 0), 0.0)));
        //}
        if (h.didHit && h.distance < minDist) {
            minDist = h.distance;
            result = h;
        }
    }
    if (useBox) {
        for (int i = 0; i < 12; i++) {
            hit h;
            h = triangleIntersect(r, createTriangle(boxVertices[boxIndices[i].x - 1], boxVertices[boxIndices[i].y - 1], boxVertices[boxIndices[i].z - 1], createMaterial(vec3(boxColor[i].x, boxColor[i].y, boxColor[i].z), vec3(0, 0, 0), 0.0)));
            if (h.didHit && h.distance < minDist) {
                minDist = h.distance;
                result = h;
            }
        }
        for (int i = 0; i < 2; i++) {
            hit h;
            h = triangleIntersect(r, createTriangle(planeVertices[planeIndices[i].x - 1], planeVertices[planeIndices[i].y - 1], planeVertices[planeIndices[i].z - 1], createMaterial(vec3(1, 1, 1), vec3(1, 1, 1), 0.0)));
            if (h.didHit && h.distance < minDist) {
                minDist = h.distance;
                result = h;
            }
        }
    }
    return result;
}



vec3 trace(ray r, inout uint state, int depth) {

    vec3 totalIllumination = vec3(0, 0, 0);
    vec3 rayColor = vec3(1, 1, 1);
    ray tracedRay = r;
    hit tracedHit;
    for (int i = 0; i < depth; i++) {
        tracedHit = collision(tracedRay);
        if (!tracedHit.didHit) {
            vec2 pixelPosition = gl_FragCoord.xy / vec2(width, height);
            totalIllumination += vec3(0.529/pixelPosition.y, 0.808/ pixelPosition.y, 0.922/ pixelPosition.y);
            break;
        }
        vec3 specularDir = reflect(tracedRay.direction, tracedHit.normal);
        vec3 diffuseDir = randDirection(state)+tracedHit.normal;
        tracedRay = createRay(tracedHit.hitPoint, mix(normalize(diffuseDir), normalize(specularDir), tracedHit.objectMaterial.smoothness));
        //tracedRay.direction = -tracedHit.hitPoint + spheres[0].center;
        totalIllumination += tracedHit.objectMaterial.emittance * rayColor * pow(0.88,float(i));

        rayColor *= tracedHit.objectMaterial.color;


    }
    return totalIllumination;
}


void main() {
    const int height = 1080;
    const int width = 1080;

    vec2 pixelPosition = gl_FragCoord.xy / vec2(width, height);

    uint rngState = uint(gl_FragCoord.y * gl_FragCoord.x)+uint(frameNumber)*uint(719393);
    uint rngState2 = uint(2);

    //camera c = createCamera(90, 1, vec3(-1, 0, 2));
    camera c = createCamera(90, 1, vec3(0, 0, 3));
    ray cameraRay = createCameraRay(pixelPosition.x, pixelPosition.y, c);
    //cameraRay.direction = quaternionRotation(vec3(0, 1, 0), cameraRay.direction, -10);
    //spheres[0] = createSphere(2, vec3(-4,4,4), createMaterial(vec3(1, 1, 1), vec3(1, 1, 1), 0.0));
    //spheres[1] = createSphere(2, vec3(0, 0, 0), createMaterial(vec3(1, 1, 1), vec3(0, 0, 0), 0));
    
    /*for (int i = 0; i < triangleNum; i++) {
        if (useNormals) {
            triangles[i] = createTriangleNormal(vertices[faces[i].x - 1], vertices[faces[i].y - 1], vertices[faces[i].z - 1], normals[normalIndices[i].x - 1], normals[normalIndices[i].y - 1], normals[normalIndices[i].z - 1], createMaterial(vec3(1, 1, 1), vec3(0, 0, 0), 0.0));
        }
        else {
            triangles[i] = createTriangle(vertices[faces[i].x - 1], vertices[faces[i].y - 1], vertices[faces[i].z - 1], createMaterial(vec3(1, 1, 1), vec3(0, 0, 0), 0.0));
        }
    } */  

    






    /*for (int i = 1; i < sphereNum; i++) {
        spheres[i] = createSphere(random(rngState2)/2, vec3(random(rngState2)*10-5, random(rngState2), random(rngState2)*6-10), createMaterial(vec3(random(rngState2), random(rngState2), random(rngState2)), vec3(0, 0, 0), random(rngState2)));
    }*/
    
    vec3 totalLight = trace(cameraRay, rngState, 5);

    color = totalLight;

    if (directOutPass) {
        color = texture(screenTexture, textCoord).xyz;
    }
    else {
        color = totalLight/frameNumber;
        if (frameNumber > 0) {
            color += texture(screenTexture, textCoord).xyz*(frameNumber-1)/frameNumber;
        }
        /*color = totalLight / 20;
        if (20 > 0) {
            color += texture(screenTexture, textCoord).xyz * (20 - 1) / 20;
        }*/
    }

}