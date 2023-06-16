#version 330 core

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
struct sphere {
	float radius;
	vec3 center;
	material material;
};
sphere createSphere(float r, vec3 c) {
    sphere s;
    s.radius = r;
    s.center = c;
    return s;
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

    c.h = tan(radians(f/2));
    //c.h = 1;
    c.viewportHeight = 2*c.h;
    c.viewportWidth = aR*c.viewportHeight;
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
hit intersect(ray r, sphere s) {
    hit h;
    float t = 0;
    vec3 v = r.origin - s.center;
    float vdotd = dot(v, r.direction);
    float discriminant = vdotd * vdotd - (dot(v,v) - s.radius * s.radius);
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

const int sphereNum = 6;
sphere spheres[sphereNum];

hit collision(ray r) {
    float minDist = 1.0/0.0;
    hit result;
    for (int i = 0; i < sphereNum; i++) {
        hit h = intersect(r, spheres[i]);
        if (h.didHit && h.distance < minDist) {
            minDist = h.distance;
            result = h;
            //result.objectMaterial = spheres[i].material;
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
    float rho = sqrt(-2 *log(random(state)));
    return rho * cos(theta);
}
ray randHemisphereRay(vec3 origin, vec3 normal, inout uint state) {
    ray r = createRay(origin, vec3(randNormalDist(state), randNormalDist(state), randNormalDist(state)));
    //r.direction *= dot(r.direction, normal);
    if (dot(r.direction, normal) < 0) {
        r.direction *= vec3(-1, -1, -1);
    }
    return r;
}
vec3 randDirection(inout uint state) {
    return (vec3(randNormalDist(state), randNormalDist(state), randNormalDist(state)));
}

vec3 trace(ray r, inout uint state, int depth) {
    vec3 totalIllumination = vec3(0, 0, 0);
    vec3 rayColor = vec3(1, 1, 1);
    ray tracedRay = r;
    hit tracedHit;
    for (int i = 0; i < depth; i++) {
        tracedHit = collision(tracedRay);
        if (!tracedHit.didHit) {
            break;
        }            
        vec3 specularDir = tracedRay.direction - 2 * tracedHit.normal * (dot(tracedHit.normal, tracedRay.direction));
        vec3 diffuseDir = randDirection(state)+ tracedHit.normal;
        tracedRay = createRay(tracedHit.hitPoint, mix(diffuseDir, specularDir, tracedHit.objectMaterial.smoothness));

        totalIllumination += tracedHit.objectMaterial.emittance * rayColor;
        
        rayColor *= tracedHit.objectMaterial.color;


        //tracedRay = randHemisphereRay(tracedHit.hitPoint, tracedHit.normal, state);
        //totalIllumination += tracedHit.objectMaterial.emittance*rayColor * dot(tracedRay.direction, tracedHit.normal) * 2;
        //rayColor *= tracedHit.objectMaterial.color;
        
    }
    return totalIllumination;
}

out vec3 color;

//uniform vec3 uColor[];

uniform float sphereVertical;

uniform vec3 camPos;

void main() {
	const int height = 1080;
	const int width = 1080;

	vec2 pixelPosition = gl_FragCoord.xy / vec2(width, height);

    uint rngState = uint(gl_FragCoord.y * gl_FragCoord.x);

    camera c = createCamera(90, 1, camPos);
    ray cameraRay = createCameraRay(pixelPosition.x, pixelPosition.y, c);

    //sphere s1 = createSphere(3, vec3(10, 8, -13.5));
    sphere s1 = createSphere(3, vec3(-3, 18, sphereVertical*-1));
    sphere s2 = createSphere(1, vec3(-4, 0, -6));
    sphere s3 = createSphere(1, vec3(-1, 0, -5.5));
    sphere s4 = createSphere(1, vec3(2, 0, -5));
    sphere s5 = createSphere(100, vec3(0, -101, 3));
    sphere s6 = createSphere(1, vec3(5, 0, -4.5));
    s1.material.color = vec3(1, 1, 1);
    s1.material.emittance = vec3(2, 2, 2);
    s2.material.emittance = vec3(0, 0, 0);
    s3.material.emittance = vec3(0, 0, 0);
    s4.material.emittance = vec3(0, 0, 0);
    s5.material.emittance = vec3(0, 0, 0);
    s6.material.emittance = vec3(0, 0, 0);
    s2.material.color = vec3(0, 0, 1);
    s3.material.color = vec3(1, 1, 1);
    s4.material.color = vec3(1, 0, 0);
    s5.material.color = vec3(1, 1, 1);
    s6.material.color = vec3(1, 1, 1);
    s1.material.smoothness = 0.0;
    s2.material.smoothness = 0.0;
    s3.material.smoothness = 0.9;
    s4.material.smoothness = 1.0;
    s5.material.smoothness = 0.5;
    s6.material.smoothness = 0.0;
    spheres[0] = s1;
    spheres[1] = s2;
    spheres[2] = s3;
    spheres[3] = s4;
    spheres[4] = s5;
    spheres[5] = s6;


    //hit sIntersect = collision(cameraRay);

    int sampleNum = 100;

    vec3 totalLight = vec3(0,0,0);
    for (int i = 0; i < sampleNum; i++) {
        totalLight += trace(cameraRay, rngState, 30);
    }
    totalLight /= sampleNum;
    color = totalLight;

    //one object intersect
    //hit sIntersect = intersect(cameraRay,s);
    /*if (sIntersect.didHit) {
        color = vec3( 1,1,1 );
    }
    else {
        color = vec3(0, 0, 0);
    }*/
    

    //random color
    //color = vec3(random(rngState), random(rngState), random(rngState));
  
}
