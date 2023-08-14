#version 330 core

#define epsilon 0.0000001

const int height = 1080;
const int width = 1080;

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
struct triangle{
    vec3 v1;
    vec3 v2;
    vec3 v3;
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

struct hit {
    bool didHit;
    float distance;
    vec3 hitPoint;
    vec3 normal;
    material objectMaterial;
};
uniform uint frameNumber;
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
    float v = f*dot(r.direction, q);

    if (v < 0.0 || u + v > 1.0) {
        result.didHit = false;
        return result;
    }

    float t = f*dot(edge2,q);
    if (t > epsilon) // ray intersection
    {
        result.hitPoint = r.origin + r.direction * t;
        result.didHit = true;
        result.distance = t;
        result.objectMaterial = tri.material;
        vec3 N = normalize(cross(edge1,edge2));
        float normalDot = dot(N, N);
        result.normal = N;
        if (false)
            result.normal = -N; //may need to change
        /*}else if (a < 0) {
            result.normal = N;
        }*/
        return result;
    }else {
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

const int sphereNum = 1;
sphere spheres[sphereNum];


const int triangleNum = 83;
triangle triangles[triangleNum];

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
    for (int i = 0; i < triangleNum; i++) {
        hit h = triangleIntersect(r, triangles[i]);
        if (h.didHit && h.distance < minDist) {
            minDist = h.distance;
            result = h;
        }
    }
    return result;
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
        vec3 specularDir = tracedRay.direction - 2 * tracedHit.normal * (dot(tracedHit.normal, tracedRay.direction));
        vec3 diffuseDir = randDirection(state)+tracedHit.normal;
        tracedRay = createRay(tracedHit.hitPoint, mix(diffuseDir, specularDir, tracedHit.objectMaterial.smoothness));
        //tracedRay.direction = -tracedHit.hitPoint + spheres[0].center;
        totalIllumination += tracedHit.objectMaterial.emittance * rayColor * pow(0.88,float(i));

        rayColor *= tracedHit.objectMaterial.color;


    }
    return totalIllumination;
}

out vec3 color;

in vec2 textCoord;
uniform sampler2D screenTexture;

uniform bool directOutPass;
uniform float sphereVertical;

uniform vec3 camPos;
uniform vec3 verticies[47];
uniform ivec3 faces[83];
uniform int verticiesSize;
uniform int facesSize;


void main() {
    const int height = 2000;
    const int width = 2000;

    vec2 pixelPosition = gl_FragCoord.xy / vec2(width, height);

    uint rngState = uint(gl_FragCoord.y * gl_FragCoord.x)+frameNumber*uint(719393);
    //uint rngState2 = uint(round(float(frameNumber)/7.0));
    uint rngState2 = uint(2);
    camera c = createCamera(90, 1, vec3(0, 0, 4));
    //camera c = createCamera(90, 1, camPos);
    ray cameraRay = createCameraRay(pixelPosition.x, pixelPosition.y, c);
    spheres[0] = createSphere(4, vec3(-4,4,4), createMaterial(vec3(1, 1, 1), vec3(1, 1, 1), 0));
    /*for (int i = 1; i < sphereNum; i++) {
        spheres[i] = createSphere(random(rngState2)/2, vec3(random(rngState2)*10-5, random(rngState2), random(rngState2)*6-10), createMaterial(vec3(random(rngState2), random(rngState2), random(rngState2)), vec3(0, 0, 0), random(rngState2)));
    }*/
    for (int i = 0; i < triangleNum; i++) { //make sure to -1 when using obj files
        triangles[i] = createTriangle(verticies[faces[i].x-1], verticies[faces[i].y-1], verticies[faces[i].z-1], createMaterial(vec3(1,1,1), vec3(0, 0, 0), 0.0));
        //triangles[i] = createTriangle(verticies[faces[i].x], verticies[faces[i].y], verticies[faces[i].z], createMaterial(vec3(1, 1, 1), vec3(0, 0, 0), 0.0));
    }   

    vec3 totalLight = trace(cameraRay, rngState, 20);


    if (directOutPass) {
        color = texture(screenTexture, textCoord).xyz;
    }
    else {
        color = totalLight/frameNumber;
        if (frameNumber > uint(0)) {
            color += texture(screenTexture, textCoord).xyz*(frameNumber-uint(1))/frameNumber;
        }
    }

}