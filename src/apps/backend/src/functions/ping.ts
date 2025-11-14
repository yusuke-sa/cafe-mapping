import { Hono } from 'hono';
import { app, HttpRequest, HttpResponseInit, InvocationContext } from '@azure/functions';

type Env = {
  Bindings: {
    invocationContext: InvocationContext;
  };
};

const api = new Hono<Env>();

api.get('/ping', (c) => {
  const name = c.req.query('name') ?? 'guest';
  c.env?.invocationContext?.log(`Ping invoked by ${name}`);

  return c.json({
    message: `Hello, ${name}!`,
    timestamp: new Date().toISOString(),
  });
});

async function honoHandler(
  request: HttpRequest,
  context: InvocationContext,
): Promise<HttpResponseInit> {
  const fetchRequest = await toFetchRequest(request);
  const response = await api.fetch(fetchRequest, {
    env: { invocationContext: context },
  });
  return fromFetchResponse(response);
}

async function toFetchRequest(request: HttpRequest): Promise<Request> {
  const method = request.method ?? 'GET';
  const init: RequestInit = {
    method,
    headers: request.headers,
  };

  if (method !== 'GET' && method !== 'HEAD') {
    init.body = await request.arrayBuffer();
  }

  return new Request(request.url, init);
}

async function fromFetchResponse(response: Response): Promise<HttpResponseInit> {
  const headers: Record<string, string> = {};
  response.headers.forEach((value, key) => {
    headers[key] = value;
  });

  const bodyText = await response.text();

  return {
    status: response.status,
    headers,
    body: bodyText,
  };
}

app.http('ping', {
  methods: ['GET'],
  authLevel: 'anonymous',
  route: 'ping',
  handler: honoHandler,
});
