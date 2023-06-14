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
camera createCamera(float f, float aR) {
    camera c;
    c.fov = f;
    c.aspectRatio = aR;

    c.h = tan(radians(f/2));
    //c.h = 1;
    c.viewportHeight = 2*c.h;
    c.viewportWidth = aR*c.viewportHeight;
    c.focalLength = 1;

    c.origin = vec3(0, 0, 0);
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

const int sphereNum = 5;
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

uint nextRandom(inout uint state)
{
    state = state * uint(747796405) + uint(2891336453);
    uint result = ((state >> ((state >> uint(28)) + uint(4))) ^ state) * uint(277803737);
    result = (result >> uint(22)) ^ result;
    return result;
}
float random(inout uint state)
{
    return nextRandom(state) / 4294967295.0;
}
float randNormalDist(inout uint state) {
    float theta = radians(360.0) * random(state);
    float rho = sqrt(-2 *log(random(state)));
    return rho * cos(theta);
}
ray randHemisphereRay(vec3 origin, vec3 normal, inout uint state) {
    ray r = createRay(origin, vec3(random(state), random(state), random(state)));
    r.direction *= dot(r.direction, normal);
    return r;
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
        tracedRay = randHemisphereRay(tracedHit.hitPoint, tracedHit.normal, state);
        totalIllumination += tracedHit.objectMaterial.emittance*rayColor;
        rayColor *= tracedHit.objectMaterial.color *dot(tracedRay.direction, tracedHit.normal) *2;
        
        
    }
    return totalIllumination;
}

out vec3 color;

//uniform vec3 uColor[];

uniform float sphereVertical;


void main() {
	const int height = 2160;
	const int width = 2160;

	vec2 pixelPosition = gl_FragCoord.xy / vec2(width, height);

    uint rngState = uint(gl_FragCoord.y * gl_FragCoord.x);

    camera c = createCamera(90, 1);
    ray cameraRay = createCameraRay(pixelPosition.x, pixelPosition.y, c);

    material objMaterial;
    objMaterial.color = vec3(0.5, 0.5, 0.5);
    objMaterial.emittance = vec3(0, 0, 0);
    material lightMaterial;
    lightMaterial.color = vec3(1, 1, 1);
    lightMaterial.emittance = vec3(1, 1, 1);

    //sphere s1 = createSphere(13, vec3(10, 8, -13.5));
    sphere s1 = createSphere(14, vec3(-3, 18, sphereVertical*-1));
    sphere s2 = createSphere(1, vec3(-3, 0, -6));
    sphere s3 = createSphere(1, vec3(0, 0, -5));
    sphere s4 = createSphere(1, vec3(3, 0, -4));
    sphere s5 = createSphere(100, vec3(0, -101, 3));
    s1.material = lightMaterial;
    s2.material = objMaterial;
    s3.material = objMaterial;
    s4.material = objMaterial;
    s5.material = objMaterial;
    s2.material.color = vec3(0, 0, 1);
    s3.material.color = vec3(0, 1, 0);
    s4.material.color = vec3(1, 0, 0);
    s5.material.color = vec3(1, 1, 1);
    spheres[0] = s1;
    spheres[1] = s2;
    spheres[2] = s3;
    spheres[3] = s4;
    spheres[4] = s5;


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
