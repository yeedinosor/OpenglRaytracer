#version 330 core

struct ray {
	bool noRay;
	vec3 direction;
	vec3 origin;

    /*ray(vec3 o, vec3 d) {
        noRay = false;
        origin = o;
        direction = normalize(d);
    }
    ray(vec3 o, vec3 d, bool nr) {
        noRay = nr;
        origin = o;
        direction = normalize(d);
    }*/
};

ray createRay(vec3 o, vec3 d) {
    ray r;
    r.origin = o;
    r.direction = normalize(d);
    return r;
}



struct material {
	vec3 color;
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

struct hit {
    bool didHit;
    float distance;
    vec3 hitPoint;
    vec3 normal;
    material objectMaterial;
};

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
    h.normal = h.hitPoint - s.center / s.radius;
    return h;
}

int sphereNum;
sphere[] spheres = sphere[](createSphere(0.5, vec3(0, 3, -5)));

hit collision(ray r) {
    float minDist = intersect(r, spheres[0]).distance;
    hit result;
    for (int i = 0; i < sphereNum; i++) {
        hit h = intersect(r, spheres[i]);
        if (h.didHit && h.distance < minDist) {
            result = h;
            result.objectMaterial = spheres[i].material;
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

out vec3 color;

uniform vec3 uColor[];


void main() {
	const int height = 1080;
	const int width = 1080;

	vec2 pixelPosition = gl_FragCoord.xy / vec2(width, height);

    uint rngState = uint(gl_FragCoord.y * gl_FragCoord.x);

    camera c = createCamera(90, 1);
    ray cameraRay = createCameraRay(pixelPosition.x, pixelPosition.y, c);

    sphere s = createSphere(0.5, vec3(0, 3, -5));
    hit sIntersect = intersect(cameraRay,s);
    if (sIntersect.didHit) {
        color = vec3( 1,1,1 );
    }
    else {
        color = vec3(0, 0, 0);
    }
    //color = vec3(random(rngState), random(rngState), random(rngState));
  
}
